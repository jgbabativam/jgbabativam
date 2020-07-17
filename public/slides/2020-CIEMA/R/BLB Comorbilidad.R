rm(list = ls())
library(BiplotML)
library(readxl)
library(tidyverse)

comor <- read_excel("./data/Comorbilidades.xlsx") %>% 
         mutate_if(is.character, trimws) %>% mutate_if(is.character, str_to_upper) %>% 
         mutate(idr = row_number()) %>%  as.data.frame()

dico <- comor %>% dplyr::select(idr, starts_with("COM")) %>%
        pivot_longer(-c("idr", "COMORBILIDADES"), 
                     names_to = "idCOM", values_to = "COM") %>% 
        dplyr::filter(!is.na(COM)) %>% 
        group_by(COM) %>% 
        mutate(frec = n()/nrow(comor),
               COMR = ifelse(COM == "NO", "NO",  ifelse(frec <= 3/nrow(comor), "OTRA", COM))) %>%
        ungroup() %>% 
        mutate(cod = ifelse(COMR == "NO", 0, 1)) %>% 
        dplyr::select(-idCOM, -COM, -frec) %>% 
        distinct() %>% 
        pivot_wider(id_cols = idr, names_from = COMR, values_from = cod) %>% 
        dplyr::select(-NO) 
dico[is.na(dico)] <- 0

skimr::skim(dico)

#set.seed(2019)
set.seed(1234)
aa <- BiplotML::bootBLB(dico[,-c(1, 9)], L = 0.03, method = "CG")


dev.off()
dev.new()

set.seed(22020)
ver <- BiplotML::LogBip(dico[,-c(1)], method = "BFGS")

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/LogBip.png", 
       BiplotML::LogBip(dico[,-c(1)], method = "BFGS"),
       width = 9, height = 9, dpi = 100, units = "in", device='png')


todo <- cbind(comor, ver$A) %>% 
        mutate(redad = ifelse(EDAD <= 45, "<= 45 años", 
                              ifelse(EDAD <=70, "46-70 años",
                                     ifelse(EDAD <=85, "71-85 años", "86 años o más")))) %>% 
       group_by(redad) %>% 
       summarise(Dim1 = median(Dim1), Dim2 = median(Dim2))


dev.new()
g1 <- plotBLB(ver, col.ind = comor$GÉNERO, legendt = "Sexo", titles = "Comorbilidades SARS-CoV-2") 

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/LogBipSex.png", 
       g1,
       width = 9, height = 9, dpi = 100, units = "in", device='png')


g2 <- g1  +   
      geom_point(aes(x = todo$Dim1, y = todo$Dim2), shape = 19, size=3.0) +
      geom_text_repel(aes(x = todo$Dim1, y = todo$Dim2), label = todo$redad)


ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/LogBipTedad.png", 
       g2,
       width = 9, height = 9, dpi = 100, units = "in", device='png')


todo2 <- cbind(comor, ver$A) %>% 
        group_by(DEPARTAMENTO) %>% 
        summarise(Dim1 = median(Dim1), Dim2 = median(Dim2)) 

dev.off()
dev.new()
g3 <- g1  +   
     geom_point(aes(x = todo2$Dim1, y = todo2$Dim2), fill="blue", shape = 21, size=2.5) +
     geom_text_repel(aes(x = todo2$Dim1, y = todo2$Dim2), label = todo2$DEPARTAMENTO, color = "blue", size = 2.5)


ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/LogBipXDpto.png", 
       g3,
       width = 9, height = 9, dpi = 100, units = "in", device='png')
