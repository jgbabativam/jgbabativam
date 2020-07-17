#####.... Programado por Giovany Babativa
rm(list=ls())
options(stringsAsFactors=FALSE)
library(tidyverse)
library(maps)
library(sf)
library(ggthemes)
library(lubridate)
library(ggpubr)
library(ggrepel)
library(readxl)
library(gganimate)
library(viridis)

divipola <- read_excel("G:/Mi unidad/GitRepos/talks/data/Divipola.xlsx") %>% 
  mutate_if(is.character, trimws)

Colombia <- read.csv("G:/Mi unidad/GitRepos/talks/data/COVID-19_en_Colombia.csv", sep = ",", encoding = "UTF-8")
Colombia$Codigo.DIVIPOLA <- sprintf("%05d", Colombia$Codigo.DIVIPOLA)

#Colombia$ciudad = iconv(Colombia$Ciudad.de.ubicación, from = 'UTF-8', to = 'ASCII//TRANSLIT') 

Colombia <- Colombia  %>% 
            mutate_if(is.character, trimws) %>% 
                mutate(Fecha.diagnostico = ifelse(Fecha.diagnostico == "SIN DATO",
                                                  fecha.reporte.web, Fecha.diagnostico))

(ver <- anti_join(Colombia, divipola, by = c("Codigo.DIVIPOLA"="DPMP")))


Colombia <- Colombia %>% 
            separate(Fecha.diagnostico, c("anio", "mes", "dia"), sep = "-")%>% 
            separate(dia, c("dia", "hora"), sep ="T")%>% 
            mutate(fecha = lubridate::date(paste(anio, mes, dia, sep = "-"))) %>% 
            dplyr::select(-dia, -mes, -anio) %>% 
            left_join(divipola, by = c("Codigo.DIVIPOLA"="DPMP")) 


colshape <-  st_read("G:/Mi unidad/GitRepos/talks/data/shape/depto.shp", stringsAsFactors=F) 


#........... Proyecciones de poblacion por edad
# https://www.dane.gov.co/index.php/estadisticas-por-tema/demografia-y-poblacion/proyecciones-de-poblacion

proyecciones <- tribble(
  ~redad,   ~poblacion,
  "0 a 9",      7863825,
  "10 a 19",      8112327,
  "20 a 29",      8551856,
  "30 a 39",      7470681,
  "40 a 49",      6130204,
  "50 a 59",      5434890,
  "60 a 69",      3795322,
  "70 a 79",      2003827,
  "80 a 89",       777513
)

Colombia <- Colombia %>% 
  mutate(redad = ifelse(Edad <= 9, "0 a 9",
                        ifelse(Edad <=19, "10 a 19",
                               ifelse(Edad <=29, "20 a 29",
                                      ifelse(Edad <=39, "30 a 39",
                                             ifelse(Edad <=49, "40 a 49",
                                                    ifelse(Edad <=59, "50 a 59",
                                                           ifelse(Edad <=69, "60 a 69",
                                                                  ifelse(Edad <=79, "70 a 79",
                                                                         ifelse(Edad <=89, "80 a 89","90 o más"))))))))))

fechas <- seq.Date(as.Date("2020-03-06"), lubridate::today()-1, 1)
Dptos <- divipola %>% 
  group_by(DP) %>% 
  summarise(temp = n()) %>% 
  ungroup() %>% 
  arrange(DP)

repEdad <- data.frame(lapply(proyecciones, rep, length(fechas))) %>%  arrange(redad)
repEdad <- data.frame(repEdad, fecha = fechas)
repDeptos <- data.frame(lapply(Dptos, rep, length(fechas))) %>% arrange(DP)  
repDeptos <- data.frame(repDeptos, fecha = fechas) %>% dplyr::select(-temp)            
colnames(repDeptos) <- c("DP", "fecha")


#............
AggDep <- Colombia %>% 
  group_by(DP, fecha) %>% 
  summarise(ncasos = n()) %>% 
  right_join(repDeptos, by = c("DP"="DP", "fecha"="fecha"))%>%
  arrange(DP, fecha) %>% 
  replace(is.na(.), 0) %>% 
  mutate(confirmados = cumsum(ncasos)) %>% 
  ungroup()

#sum(AggDep$ncasos)   #test

AggCol <- Colombia %>% 
  group_by(fecha) %>% 
  summarise(ncasos = n()) %>% 
  mutate(confirmados = cumsum(ncasos))

library(RColorBrewer)
fil <- AggDep %>% dplyr::filter(fecha == lubridate::today()-1)   


dev.off()
dev.new()

g2 <- colshape %>% 
      full_join(AggDep, by=c("DPTO"="DP")) %>% 
      mutate(is.na(confirmados), 0) %>% 
      ggplot() +
      geom_sf(aes(fill = confirmados)) +
      scale_fill_gradientn(colours=brewer.pal(9,"Reds")) + 
      geom_sf_text(aes(label = confirmados), colour = "darkblue", size = 5) +     
      transition_manual(fecha) +
      theme(axis.line=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        legend.position="none",
        panel.background=element_blank(),
        panel.border=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        panel.grid.major.x = element_line( size=.1, color="grey" ),
        panel.grid.minor.x = element_line( size=.1, color="grey" ),
        plot.title=element_text(size=25, hjust=0.5, face="bold", colour="grey", vjust=-1),
        plot.subtitle=element_text(size=18, hjust=0.5, face="italic", color="grey"),
        plot.caption =element_text(size=8, hjust=0.5, face="italic", color="grey"),
        plot.background=element_blank(),
        plot.margin = margin(2,2, 2, 4, "cm")) +  
      labs(title = "Casos SARS-CoV2 al: {current_frame}",
           caption = paste0("Fuente: www.ins.gov.co. Fecha de corte: ", Sys.Date()-1, ". @jgbabativa")) + 
      theme_void()

#animate(g2, 200, fps = 5,  width = 1200, height = 1000)
#anim_save("G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/SarsCol.gif")


####### Grafico doble eje

pob <- read_excel("G:/Mi unidad/GitRepos/talks/data/poblacion.xlsx")


tasas <- Colombia %>% 
         group_by(DP, fecha) %>% 
         summarise(ncasos = n())  %>% 
         right_join(repDeptos, by = c("DP"="DP", "fecha"="fecha"))%>%
         arrange(DP, fecha) %>% 
         replace(is.na(.), 0) %>% 
         mutate(confirmados = cumsum(ncasos)) %>%
         ungroup() %>% 
         left_join(pob, by = "DP") %>%
         mutate(tasa = round(confirmados/poblacion * 100000, 1)) %>% 
  group_by(fecha) %>% 
         mutate(rank = rank(-tasa)) %>% 
         ungroup() 

tasas[tasas$Departamento == "Archipiélago de San Andrés, Providencia y Santa Catalina", "Departamento"] <- "San Andrés"

names(tasas)

anim <- ggplot(tasas, aes(rank, group = Departamento, 
                            fill = as.factor(Departamento), color = as.factor(Departamento))) +
  geom_tile(aes(y = tasa/2,
                height = tasa,
                width = 0.9), alpha = 0.8, color = NA) +
  geom_text(aes(y = 0, label = paste(Departamento, " ")), vjust = 0.2, hjust = 1) +
  geom_text(aes(y=tasa,label = as.character(round(tasa,1)), hjust=0)) +
  coord_flip(clip = "off", expand = FALSE) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_reverse() +
  guides(color = FALSE, fill = FALSE) +
  theme(axis.line=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        legend.position="none",
        panel.background=element_blank(),
        panel.border=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        panel.grid.major.x = element_line( size=.1, color="grey" ),
        panel.grid.minor.x = element_line( size=.1, color="grey" ),
        plot.title=element_text(size=25, hjust=0.5, face="bold", colour="grey", vjust=-1),
        plot.subtitle=element_text(size=18, hjust=0.5, face="italic", color="grey"),
        plot.caption =element_text(size=8, hjust=0.5, face="italic", color="grey"),
        plot.background=element_blank(),
        plot.margin = margin(2,2, 2, 4, "cm")) +
  transition_states(fecha, transition_length = 4, state_length = 1) +
  view_follow(fixed_x = TRUE)  +
  labs(title = 'Tasa por 100 mil hab.: {closest_state}',  
       subtitle  =  "Departamental",
       caption  = "@jgbabativam") 

animate(anim, 200, fps = 2,  width = 1200, height = 1000)
anim_save("G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/TasaDptal.gif")


names(tasas)

p1 <- tasas %>% 
  ggplot(aes(x = fecha, y = tasa, fill=Departamento)) +
  geom_line(size = 1.0, alpha = .9, color="blue") + 
  geom_point(aes(group = seq_along(fecha))) +
  geom_text_repel(aes(label = as.character(round(tasa, 1))), size=3.5, segment.color = "grey50", arrow = arrow(length = unit(0.03, "npc"), type = "closed", ends = "first"), hjust=1.0)+
  xlab("Fecha")+
  ylab("Tasa de infección") +
  labs(title="Evolución SARS-CoV-2: Colombia",
       caption="@jgbabativam")+
  transition_reveal(tasa)+
  theme_bw() +
  theme(legend.key = element_blank(), legend.title = element_blank(), legend.position = "none") 

p1



dia <- tasas %>% 
  dplyr::filter(fecha == lubridate::today()-1) 

save(dia, file = "G:/Mi unidad/GitRepos/talks/talks/Cartagena/data/dia.rda")

dev.off()
dev.new()
g1 <- ggplot(dia, aes(reorder(Departamento, tasa), y = tasa)) +
  geom_bar(stat = "identity", color="black", fill="blue") + 
  geom_text(aes(label=round(tasa,1)), hjust=-0.2, color="black",  position = position_dodge(0.9), size=3.5)+
  coord_flip() +
  xlab("Departamento") + ylab("Tasa") + ylim(0, max(dia$tasa) + 10) + theme_bw()
ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/tasa.png", g1,
       width = 12, height = 8, dpi = 100, units = "in", device='png')

dev.off()
dev.new()
g2 <-  ggplot(dia, aes(reorder(Departamento, confirmados), y = confirmados)) +
  geom_bar(stat = "identity", color="black", fill="blue") + 
  geom_text(aes(label=round(confirmados,1)), hjust=-0.2, color="black",  position = position_dodge(0.9), size=3.5)+
  coord_flip() +
  xlab("Departamento") + ylab("Número de casos") + ylim(0, max(dia$confirmados) + 10) + theme_bw()

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/casos.png", g2,
       width = 12, height = 8, dpi = 100, units = "in", device='png')



##############------

AggCol <- AggCol %>% 
          mutate(log = log(confirmados))



g3 <- AggCol


g1 <- AggCol %>% 
  ggplot(aes(x = fecha, y = confirmados), size = 1.5, alpha = .9) + 
  geom_line(size = 1.2, alpha = .9) +
  scale_colour_manual(values = "blue") +
  xlab("Fecha")+
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
  ylab("Número de casos") +
  labs(title="Número de casos confirmados",
       caption= paste0("INS. Fecha de corte: ", Sys.Date()-1))+
  theme_bw() + theme(axis.text.x = element_text(angle = 90, hjust = 1),
                     plot.title = element_text(hjust = 0.5, size = 14),
                     plot.caption = element_text(hjust = 1, size = 10),
                     axis.title=element_text(face="bold",size="11"))
dev.off()
dev.new()
g1

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/CasosNal.png", g1,
       width = 8, height = 8, dpi = 100, units = "in", device='png')


g2 <- AggCol %>% 
  ggplot(aes(x = fecha, y = log), size = 1.5, alpha = .9) + 
  geom_line(size = 1.2, alpha = .9) +
  scale_colour_manual(values = "blue") +
  xlab("Fecha")+
  ylab("Log(Número de casos)") +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
  labs(title="Logaritmo del número de casos confirmados",
       caption= paste0("INS. Fecha de corte: ", Sys.Date()-1))+
  theme_bw() + theme(axis.text.x = element_text(angle = 90, hjust = 1),
                     plot.title = element_text(hjust = 0.5, size = 14),
                     plot.caption = element_text(hjust = 1, size = 10),
                     axis.title=element_text(face="bold",size="11"))

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Cartagena/images/logCasosNal.png", g2,
       width = 8, height = 8, dpi = 100, units = "in", device='png')

dev.off()
dev.new()
g2
