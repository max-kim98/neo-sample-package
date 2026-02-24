package backend

type Config struct {
  ProjectName  string
  Version      string
  Listen       string
  PIDPath      string
  DatabasePath string
}

type EchoRequest struct {
  Message string `json:"message"`
}

type Item struct {
  ID        string `json:"id"`
  Name      string `json:"name"`
  CreatedAt string `json:"createdAt"`
}
