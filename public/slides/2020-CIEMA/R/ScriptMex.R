
#### Comparación de países

rm(list = ls())
options(stringAsFactor = F)
library(tidyverse)
library(maps)
library(ggthemes)
library(lubridate)
library(ggpubr)
library(ggrepel)

url <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/"

#......

confirmados <- read.csv(paste0(url, "time_series_covid19_confirmed_global.csv")) %>%
  pivot_longer(-c("Province.State", "Country.Region", "Lat", "Long"), 
               names_to = "fecha", values_to = "nro_confirmados") %>%    
  separate(fecha, c("mes", "dia", "anno"), sep = "\\.") %>%                
  mutate(mes = gsub("X", "", mes),
         anno = paste0("20", anno),
         fecha = lubridate::date(paste(anno, mes, dia, sep = "-")) ) %>%   
  dplyr::select(Country.Region, Province.State, Lat, Long, fecha, nro_confirmados)   


muertos  <- read.csv(paste0(url, "time_series_covid19_deaths_global.csv")) %>%
  pivot_longer(-c("Province.State", "Country.Region", "Lat", "Long"), 
               names_to = "fecha", values_to = "nro_muertos") %>%
  separate(fecha, c("mes", "dia", "anno"), sep = "\\.") %>%
  mutate(mes = gsub("X", "", mes),
         anno = paste0("20", anno),
         fecha = lubridate::date(paste(anno, mes, dia, sep = "-")) ) %>%
  dplyr::select(Country.Region, Province.State, Lat, Long, fecha, nro_muertos)


recuperados <- read.csv(paste0(url, "time_series_covid19_recovered_global.csv")) %>%
  pivot_longer(cols = matches("^X[0-9]{1,2}"), names_to = "fecha", values_to = "nro_recuperados") %>%
  separate(fecha, c("mes", "dia", "anno"), sep = "\\.") %>%
  mutate(mes = gsub("X", "", mes),
         anno = paste0("20", anno),
         fecha = lubridate::date(paste(anno, mes, dia, sep = "-")) ) %>%
  dplyr::select(Country.Region, Province.State, Lat, Long, fecha, nro_recuperados)

confirmados$Province.State=as.character(confirmados$Province.State)
muertos$Province.State = as.character(muertos$Province.State)
recuperados$Province.State=as.character(recuperados$Province.State)

total <- full_join(confirmados, muertos,  
                   by = c("Country.Region", "Province.State", "Lat", "Long", "fecha")) %>% 
  left_join(recuperados, by = c("Country.Region", "Province.State", "Lat", "Long", "fecha"))



###---- Análisis de los días desde el brote

paises <- c("Brazil" ,"Colombia", "Ecuador", "Spain", "Mexico", "Costa Rica", "Panama")

diasv <- total %>% 
  dplyr::filter(Country.Region %in% paises  & nro_confirmados > 0) %>% 
  group_by(Country.Region) %>% 
  mutate(dias = row_number()) %>% 
  ungroup()

diasv$newcases <-  with(diasv, ifelse(dias == 1, nro_confirmados, nro_confirmados - lag(nro_confirmados)))

fecha <- total %>% 
  dplyr::filter(fecha == lubridate::today()-1 & nro_confirmados > 0)

#### Graficas comparativas
rday <- max(diasv[diasv$Country.Region=="Brazil", "dias"])
paleta <- c("#73ACDF", "darkgreen","blue", "red", "purple", "darkgray", "#FFC30F", "orange")

ver <- diasv %>% 
  dplyr::filter(dias <= rday)

vmax <- max(ver$nro_confirmados)
cmax <- max(ver$newcases)

g2 <- diasv %>% 
  ggplot(aes(x = dias, y = log(nro_confirmados), group = Country.Region), size = 1.5, alpha = .9) + 
  geom_line(aes(color=Country.Region), size = 1.2, alpha = .9) +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(from = 0, to=500, by = 7)) +
  scale_y_continuous(breaks = seq(from = 0, to=500000, by = 10000)) +
  geom_text_repel(data = dplyr::filter(diasv, fecha == lubridate::today()-1), 
                  aes(x = dias+3, y= log(nro_confirmados), 
                      label = Country.Region, color = Country.Region)) +
  xlab("días transcurridos desde el caso 1")+
  ylab("Log(número de casos)")  +
  labs(title="Logaritmo del número de casos confirmados",
       caption= paste0("Fuente: Universidad Johns Hopkins. Fecha de corte: ", Sys.Date()-1))+
  theme_bw() + theme(legend.position = "none") 

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/comparapaises.png", g2,
       width = 12, height = 8, dpi = 100, units = "in", device='png')



####-------------------- Grafica dividida

paises2 <- c("Brazil", "Ecuador", "Spain", "Mexico", "Costa Rica", "Panama")

dataCol <- total %>% 
  dplyr::filter(Country.Region %in% paises2 & nro_confirmados >0 ) %>% 
  mutate(confirmac = nro_confirmados - (nro_muertos + nro_recuperados)) %>% 
  group_by(Country.Region) %>% 
  mutate(dias = row_number(),
         newcases = ifelse(dias == 1, nro_confirmados, nro_confirmados - lag(nro_confirmados))) %>%
    ungroup() %>% 
  dplyr::select(-nro_confirmados) %>% 
  pivot_longer(-c("Country.Region", "Province.State", "Lat", "Long", "fecha", "dias"),
               names_to = "Tipo", values_to = "Cantidad") 

databar <- dataCol %>% 
  dplyr::filter(Country.Region %in% paises2,  !Tipo == "newcases") %>% 
  mutate(orden = ifelse(Tipo == "nro_muertos", 3, ifelse(Tipo == "confirmac", 2, ifelse(Tipo == "nro_recuperados", 1, 4)))) %>% 
  arrange(dias, -orden) %>% 
  group_by(Country.Region, dias) %>% 
  mutate(lab_ypos = ifelse(orden !=4, cumsum(Cantidad) - 0.5 * Cantidad, NA)) %>% 
  ungroup()

newcases <- dplyr::filter(dataCol, Tipo == "newcases") %>% 
            rename(newcases = Cantidad)


paleta <- c("#0073C2FF", "#EFC000FF", "red")

d1 <- databar %>% 
      dplyr::filter(Country.Region == "Brazil" & fecha > lubridate::today()-30) %>% 
      ggplot()  +
  geom_bar(aes(x = fecha, y = Cantidad, fill = as.factor(orden)), 
           position = "stack", stat="identity") +
  scale_fill_manual(values = paleta, labels = c("Altas", "En tratamiento", "Fallecidos")) +
  geom_text(data = databar %>% dplyr::filter(fecha == lubridate::today()-1 & Country.Region == "Brazil"),
            aes(x = fecha+1, y = lab_ypos, label = Cantidad),  color=c("red", "#EFC000FF", "#0073C2FF"), fontface = 2, size=3.5)+
  ylab("Cantidad de fallecidos, en tratamiento y altas") +
  geom_line(data = newcases%>% 
              dplyr::filter(Country.Region == "Brazil" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, color = "Nuevos positivos"), inherit.aes = FALSE)+
  geom_point(data = newcases%>% 
               dplyr::filter(Country.Region == "Brazil" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, color = "Nuevos positivos"), inherit.aes = FALSE) +
  scale_color_manual(NULL, values = "black") +
  geom_text_repel(data = newcases%>% 
                    dplyr::filter(Country.Region == "Brazil" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, label = newcases, fontface=1), size = 3.5) +
  scale_linetype_manual(NULL, values = 1) +
  scale_y_continuous(sec.axis = sec_axis(~./20.0, name = "Nuevos positivos")) +
  scale_x_date(date_breaks = "1 day", date_labels = "%b %d") +
  labs(title="Situación epidemiológica SARS-CoV-2: Brasil",
       caption="Fuente: Universidad Johns Hopkins", fill = " ") +
  theme_bw() 


d1r <- d1 + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 14),
        plot.caption = element_text(hjust = 1, size = 10),
        axis.title=element_text(face="bold",size="11"))

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/DobleBrasil.png", d1r,
       width = 15, height = 9, dpi = 100, units = "in", device='png')


#############################  Mexico
d2 <- databar %>% 
  dplyr::filter(Country.Region == "Mexico" & fecha > lubridate::today()-30) %>% 
  ggplot()  +
  geom_bar(aes(x = fecha, y = Cantidad, fill = as.factor(orden)), 
           position = "stack", stat="identity") +
  scale_fill_manual(values = paleta, labels = c("Altas", "En tratamiento", "Fallecidos")) +
  geom_text(data = databar %>% 
              dplyr::filter(fecha == lubridate::today()-1 & Country.Region == "Mexico"),
            aes(x = fecha+1, y = lab_ypos, label = Cantidad),  color=c("red", "#EFC000FF", "#0073C2FF"), fontface = 2, size=3.5)+
  ylab("Cantidad de fallecidos, en tratamiento y altas") +
  geom_line(data = newcases%>% 
              dplyr::filter(Country.Region == "Mexico" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, color = "Nuevos positivos"), inherit.aes = FALSE)+
  geom_point(data = newcases%>% 
               dplyr::filter(Country.Region == "Mexico" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, color = "Nuevos positivos"), inherit.aes = FALSE) +
  scale_color_manual(NULL, values = "black") +
  geom_text_repel(data = newcases%>% 
                    dplyr::filter(Country.Region == "Mexico" & fecha > lubridate::today()-30), aes(x = fecha, y=newcases*20.0, label = newcases, fontface=1), size = 3.5) +
  scale_linetype_manual(NULL, values = 1) +
  scale_y_continuous(sec.axis = sec_axis(~./20.0, name = "Nuevos positivos")) +
  scale_x_date(date_breaks = "1 day", date_labels = "%b %d") +
  labs(title="Situación epidemiológica SARS-CoV-2: México",
       caption="Fuente: Universidad Johns Hopkins", fill = " ") +
  theme_bw() 


d2r <- d2 + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 14),
        plot.caption = element_text(hjust = 1, size = 10),
        axis.title=element_text(face="bold",size="11"))

dev.new()
ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/DobleMexico.png", d2r,
       width = 15, height = 9, dpi = 100, units = "in", device='png')



##### España
#############################  Mexico
d3 <-  databar %>% 
  dplyr::filter(Country.Region == "Spain" & fecha > lubridate::today()-90) %>% 
  ggplot()  +
  geom_bar(aes(x = fecha, y = Cantidad, fill = as.factor(orden)), 
           position = "stack", stat="identity") +
  scale_fill_manual(values = paleta, labels = c("Altas", "En tratamiento", "Fallecidos")) +
  geom_text(data = databar %>% dplyr::filter(fecha == lubridate::today()-1 & 
                                               Country.Region == "Spain"),
            aes(x = fecha+3, y = lab_ypos, label = Cantidad),  color=c("red", "#EFC000FF", "#0073C2FF"), fontface = 2, size=3.5)+
  ylab("Cantidad de fallecidos, en tratamiento y altas") +
  scale_x_date(date_breaks = "1 day", date_labels = "%b %d") +
  labs(title="Situación epidemiológica SARS-CoV-2: España",
       caption="Fuente: Universidad Johns Hopkins", fill = " ") +
  theme_bw() 


d3r <- d3 + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 14),
        plot.caption = element_text(hjust = 1, size = 10),
        axis.title=element_text(face="bold",size="11"))

dev.new()
d3r

ggsave(file = "G:/Mi unidad/GitRepos/talks/talks/Mexico/images/DobleSpain.png", d3r,
       width = 15, height = 9, dpi = 100, units = "in", device='png')

