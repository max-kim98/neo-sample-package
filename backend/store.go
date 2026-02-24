package backend

import (
  "encoding/json"
  "fmt"
  "os"
  "path/filepath"
  "sync"
  "time"
)

type persistedState struct {
  Items []Item `json:"items"`
}

type Store struct {
  mu           sync.RWMutex
  databasePath string
  order        []string
  items        map[string]Item
}

func NewStore(databasePath string) *Store {
  s := &Store{
    databasePath: databasePath,
    order:        make([]string, 0),
    items:        make(map[string]Item),
  }

  _ = s.load()
  return s
}

func (s *Store) Create(name string) (Item, error) {
  s.mu.Lock()
  defer s.mu.Unlock()

  id := fmt.Sprintf("item-%d", time.Now().UnixNano())
  item := Item{
    ID:        id,
    Name:      name,
    CreatedAt: time.Now().UTC().Format(time.RFC3339),
  }

  s.items[id] = item
  s.order = append(s.order, id)

  if err := s.persist(); err != nil {
    return Item{}, err
  }
  return item, nil
}

func (s *Store) List() []Item {
  s.mu.RLock()
  defer s.mu.RUnlock()

  out := make([]Item, 0, len(s.order))
  for _, id := range s.order {
    if item, ok := s.items[id]; ok {
      out = append(out, item)
    }
  }
  return out
}

func (s *Store) Delete(id string) (bool, error) {
  s.mu.Lock()
  defer s.mu.Unlock()

  if _, ok := s.items[id]; !ok {
    return false, nil
  }

  delete(s.items, id)
  next := make([]string, 0, len(s.order))
  for _, curr := range s.order {
    if curr != id {
      next = append(next, curr)
    }
  }
  s.order = next

  if err := s.persist(); err != nil {
    return false, err
  }
  return true, nil
}

func (s *Store) load() error {
  if s.databasePath == "" {
    return nil
  }

  raw, err := os.ReadFile(s.databasePath)
  if err != nil {
    if os.IsNotExist(err) {
      return nil
    }
    return err
  }

  var state persistedState
  if err := json.Unmarshal(raw, &state); err != nil {
    return err
  }

  s.order = make([]string, 0, len(state.Items))
  s.items = make(map[string]Item, len(state.Items))
  for _, item := range state.Items {
    s.items[item.ID] = item
    s.order = append(s.order, item.ID)
  }

  return nil
}

func (s *Store) persist() error {
  if s.databasePath == "" {
    return nil
  }

  items := make([]Item, 0, len(s.order))
  for _, id := range s.order {
    if item, ok := s.items[id]; ok {
      items = append(items, item)
    }
  }

  state := persistedState{Items: items}
  raw, err := json.MarshalIndent(state, "", "  ")
  if err != nil {
    return err
  }

  if err := os.MkdirAll(filepath.Dir(s.databasePath), 0o755); err != nil {
    return err
  }
  return os.WriteFile(s.databasePath, raw, 0o644)
}
