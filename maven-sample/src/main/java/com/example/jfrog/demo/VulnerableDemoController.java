package com.example.jfrog.demo;

import java.io.IOException;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class VulnerableDemoController {

    @GetMapping("/demo/ping")
    public String pingHost(@RequestParam String host) throws IOException {
        Runtime.getRuntime().exec("ping -c 1 " + host);
        return "scheduled";
    }
}
