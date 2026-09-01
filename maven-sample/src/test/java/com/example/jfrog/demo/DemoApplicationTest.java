package com.example.jfrog.demo;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

class DemoApplicationTest {

    @Test
    void mainClassIsLoadable() {
        assertDoesNotThrow(() -> Class.forName("com.example.jfrog.demo.DemoApplication"));
    }
}
