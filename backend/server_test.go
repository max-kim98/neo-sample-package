package backend

import (
  "bytes"
  "encoding/json"
  "net/http"
  "net/http/httptest"
  "strings"
  "testing"
)

func TestResolveProjectNamePrefersEnv(t *testing.T) {
  t.Setenv("PROJECT_NAME", "from-env")

  got := resolveProjectName("/tmp/sample-binary")
  if got != "from-env" {
    t.Fatalf("expected env project name, got %q", got)
  }
}

func TestResolveProjectNameFallsBackToBinary(t *testing.T) {
  t.Setenv("PROJECT_NAME", "")

  got := resolveProjectName("C:/work/neo-demo.exe")
  if got != "neo-demo" {
    t.Fatalf("expected fallback name neo-demo, got %q", got)
  }
}

func TestAPIHealthVersionEchoAndItems(t *testing.T) {
  cfg := Config{
    ProjectName:  "project-alpha",
    Version:      Version,
    Listen:       "http://127.0.0.1:12345",
    PIDPath:      "./.backend/pid",
    DatabasePath: "",
  }

  store := NewStore("")
  handler := newAPIHandler(cfg, store)
  srv := httptest.NewServer(handler)
  defer srv.Close()

  t.Run("health", func(t *testing.T) {
    resp, err := http.Get(srv.URL + "/api/health")
    if err != nil {
      t.Fatalf("health request failed: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
      t.Fatalf("expected 200, got %d", resp.StatusCode)
    }
  })

  t.Run("version", func(t *testing.T) {
    resp, err := http.Get(srv.URL + "/api/version")
    if err != nil {
      t.Fatalf("version request failed: %v", err)
    }
    defer resp.Body.Close()

    var got map[string]any
    if err := json.NewDecoder(resp.Body).Decode(&got); err != nil {
      t.Fatalf("decode version response: %v", err)
    }

    if got["name"] != "project-alpha" {
      t.Fatalf("expected name project-alpha, got %#v", got["name"])
    }
    if got["version"] != Version {
      t.Fatalf("expected version %s, got %#v", Version, got["version"])
    }
  })

  t.Run("echo", func(t *testing.T) {
    payload := bytes.NewBufferString(`{"message":"hello"}`)
    resp, err := http.Post(srv.URL+"/api/echo", "application/json", payload)
    if err != nil {
      t.Fatalf("echo request failed: %v", err)
    }
    defer resp.Body.Close()

    var got map[string]any
    if err := json.NewDecoder(resp.Body).Decode(&got); err != nil {
      t.Fatalf("decode echo response: %v", err)
    }
    if got["message"] != "hello" {
      t.Fatalf("expected message hello, got %#v", got["message"])
    }
  })

  t.Run("items crud", func(t *testing.T) {
    createReq, err := http.NewRequest(http.MethodPost, srv.URL+"/api/items", strings.NewReader(`{"name":"first"}`))
    if err != nil {
      t.Fatalf("new create request: %v", err)
    }
    createReq.Header.Set("Content-Type", "application/json")

    createResp, err := http.DefaultClient.Do(createReq)
    if err != nil {
      t.Fatalf("create item request failed: %v", err)
    }
    defer createResp.Body.Close()

    if createResp.StatusCode != http.StatusCreated {
      t.Fatalf("expected 201, got %d", createResp.StatusCode)
    }

    var created map[string]any
    if err := json.NewDecoder(createResp.Body).Decode(&created); err != nil {
      t.Fatalf("decode create response: %v", err)
    }

    id, ok := created["id"].(string)
    if !ok || id == "" {
      t.Fatalf("expected created id, got %#v", created["id"])
    }

    listResp, err := http.Get(srv.URL + "/api/items")
    if err != nil {
      t.Fatalf("list request failed: %v", err)
    }
    defer listResp.Body.Close()

    var listBody map[string]any
    if err := json.NewDecoder(listResp.Body).Decode(&listBody); err != nil {
      t.Fatalf("decode list response: %v", err)
    }

    items, ok := listBody["items"].([]any)
    if !ok || len(items) != 1 {
      t.Fatalf("expected one item, got %#v", listBody["items"])
    }

    delReq, err := http.NewRequest(http.MethodDelete, srv.URL+"/api/items/"+id, nil)
    if err != nil {
      t.Fatalf("new delete request: %v", err)
    }
    delResp, err := http.DefaultClient.Do(delReq)
    if err != nil {
      t.Fatalf("delete request failed: %v", err)
    }
    defer delResp.Body.Close()

    if delResp.StatusCode != http.StatusOK {
      t.Fatalf("expected 200 from delete, got %d", delResp.StatusCode)
    }
  })
}
