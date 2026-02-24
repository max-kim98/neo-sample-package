package backend

import (
  "context"
  "encoding/json"
  "errors"
  "flag"
  "fmt"
  "log"
  "net/http"
  "net/url"
  "os"
  "os/signal"
  "path/filepath"
  "strings"
  "syscall"
  "time"
)

var Version = "0.0.0-dev"

const (
  defaultListen       = "http://127.0.0.1:12345"
  defaultPIDPath      = "./.backend/pid"
  defaultDatabasePath = "../storage/.data.json"
)

func Run() int {
  cfg, err := configFromArgs(os.Args[1:], os.Args[0])
  if err != nil {
    log.Printf("failed to parse config: %v", err)
    return 1
  }

  if err := writePID(cfg.PIDPath); err != nil {
    log.Printf("failed to write pid file: %v", err)
    return 1
  }
  defer func() {
    _ = os.Remove(cfg.PIDPath)
  }()

  addr, err := listenAddress(cfg.Listen)
  if err != nil {
    log.Printf("invalid listen value %q: %v", cfg.Listen, err)
    return 1
  }

  srv := &http.Server{
    Addr:              addr,
    Handler:           newAPIHandler(cfg, NewStore(cfg.DatabasePath)),
    ReadHeaderTimeout: 5 * time.Second,
  }

  errs := make(chan error, 1)
  go func() {
    errs <- srv.ListenAndServe()
  }()

  signals := make(chan os.Signal, 1)
  signal.Notify(signals, os.Interrupt, syscall.SIGTERM)

  select {
  case sig := <-signals:
    log.Printf("received signal: %s", sig.String())
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
      log.Printf("graceful shutdown failed: %v", err)
      return 1
    }
    return 0
  case err := <-errs:
    if errors.Is(err, http.ErrServerClosed) {
      return 0
    }
    log.Printf("server exited: %v", err)
    return 1
  }
}

func configFromArgs(args []string, executable string) (Config, error) {
  fs := flag.NewFlagSet("backend", flag.ContinueOnError)
  fs.SetOutput(os.Stderr)

  listen := fs.String("listen", defaultListen, "listen address")
  pidPath := fs.String("pid", defaultPIDPath, "pid file path")
  databasePath := fs.String("database", defaultDatabasePath, "database file path")

  if err := fs.Parse(args); err != nil {
    return Config{}, err
  }

  return Config{
    ProjectName:  resolveProjectName(executable),
    Version:      Version,
    Listen:       *listen,
    PIDPath:      *pidPath,
    DatabasePath: *databasePath,
  }, nil
}

func resolveProjectName(binaryPath string) string {
  if v := strings.TrimSpace(os.Getenv("PROJECT_NAME")); v != "" {
    return v
  }

  base := filepath.Base(binaryPath)
  base = strings.TrimSuffix(base, filepath.Ext(base))
  if base == "" || base == "." {
    return "unknown-project"
  }
  return base
}

func listenAddress(value string) (string, error) {
  if strings.Contains(value, "://") {
    parsed, err := url.Parse(value)
    if err != nil {
      return "", err
    }
    if parsed.Host == "" {
      return "", fmt.Errorf("missing host in listen URL")
    }
    return parsed.Host, nil
  }

  if strings.TrimSpace(value) == "" {
    return "", fmt.Errorf("empty listen value")
  }
  return value, nil
}

func newAPIHandler(cfg Config, store *Store) http.Handler {
  mux := http.NewServeMux()

  mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
      writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method not allowed"})
      return
    }

    writeJSON(w, http.StatusOK, map[string]any{
      "status":  "ok",
      "service": cfg.ProjectName,
      "time":    time.Now().UTC().Format(time.RFC3339),
    })
  })

  mux.HandleFunc("/api/version", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
      writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method not allowed"})
      return
    }

    writeJSON(w, http.StatusOK, map[string]any{
      "name":    cfg.ProjectName,
      "version": cfg.Version,
    })
  })

  mux.HandleFunc("/api/echo", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
      writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method not allowed"})
      return
    }

    var req EchoRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
      writeJSON(w, http.StatusBadRequest, map[string]any{"error": "invalid JSON"})
      return
    }

    writeJSON(w, http.StatusOK, map[string]any{
      "message":  req.Message,
      "echoedAt": time.Now().UTC().Format(time.RFC3339),
    })
  })

  mux.HandleFunc("/api/items", func(w http.ResponseWriter, r *http.Request) {
    switch r.Method {
    case http.MethodGet:
      writeJSON(w, http.StatusOK, map[string]any{"items": store.List()})
    case http.MethodPost:
      var req struct {
        Name string `json:"name"`
      }
      if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeJSON(w, http.StatusBadRequest, map[string]any{"error": "invalid JSON"})
        return
      }

      name := strings.TrimSpace(req.Name)
      if name == "" {
        writeJSON(w, http.StatusBadRequest, map[string]any{"error": "name is required"})
        return
      }

      item, err := store.Create(name)
      if err != nil {
        writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to create item"})
        return
      }

      writeJSON(w, http.StatusCreated, item)
    default:
      writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method not allowed"})
    }
  })

  mux.HandleFunc("/api/items/", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodDelete {
      writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"error": "method not allowed"})
      return
    }

    id := strings.TrimPrefix(r.URL.Path, "/api/items/")
    if strings.TrimSpace(id) == "" {
      writeJSON(w, http.StatusBadRequest, map[string]any{"error": "missing item id"})
      return
    }

    deleted, err := store.Delete(id)
    if err != nil {
      writeJSON(w, http.StatusInternalServerError, map[string]any{"error": "failed to delete item"})
      return
    }

    if !deleted {
      writeJSON(w, http.StatusNotFound, map[string]any{"error": "item not found"})
      return
    }

    writeJSON(w, http.StatusOK, map[string]any{"deleted": id})
  })

  return mux
}

func writePID(pidPath string) error {
  if err := os.MkdirAll(filepath.Dir(pidPath), 0o755); err != nil {
    return err
  }
  return os.WriteFile(pidPath, []byte(fmt.Sprintf("%d", os.Getpid())), 0o644)
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(status)
  _ = json.NewEncoder(w).Encode(payload)
}
