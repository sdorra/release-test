package main

import (
  "net/http"
  "strings"
  "fmt"
)

var (
  Version = "x.y.z"
  CommitID = "unknown"
)

func sayHello(w http.ResponseWriter, r *http.Request) {
  message := r.URL.Path
  message = strings.TrimPrefix(message, "/")
  message = "Hello " + message
  w.Write([]byte(message))
}

func main() {
  fmt.Printf("starting %s-%s ...\n", Version, CommitID)

  http.HandleFunc("/", sayHello)
  if err := http.ListenAndServe(":8080", nil); err != nil {
    panic(err)
  }
}
