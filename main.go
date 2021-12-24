package main

import (
	"fmt"
	"log"
)

func main() {
	fmt.Println("golang")
	test("demo")
	for {
	}
}

func test(str string) {
	log.Println(str)
}
