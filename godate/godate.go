package main

import (
	"fmt"
	"time"
)

const (
	ISO8660 = "2006-01-02T15:04:05.999999Z0700"
)

func main() {
	now := time.Now().Local()
	fmt.Println(now.Format(ISO8660))
}
