package br.edu.iftm.teste;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class Teste {
    
    @RequestMapping("/alo")
    public String master(Model modelo) {
        modelo.addAttribute("x1",Math.round(Math.random()*60)+1);
        modelo.addAttribute("x2",Math.round(Math.random()*60)+1);
        modelo.addAttribute("x3",Math.round(Math.random()*60)+1);
        modelo.addAttribute("x4",Math.round(Math.random()*60)+1);
        modelo.addAttribute("x5",Math.round(Math.random()*60)+1);
        modelo.addAttribute("x6",Math.round(Math.random()*60)+1);
        return "view1";
    }
}
