---
title: "Graficando funciones con ggplot2"
author: "Giovany Babativa"
tags: 
    - R
    - ggplot
categories: 
    - R
    - ggplot
subtitle: ''
summary: "Aprenda una forma simple de graficar cualquier función matemática con el paquete ggplot2"
date: '2020-07-14'
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image: 
  caption: '[Photo by Robert Lukeman on Unsplash](https://unsplash.com/photos/_RBcxo9AU-U)'
  focal_point: ""
  preview_only: no

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---



Cuando tenía la necesidad de graficar una función solía recurrir a programas como `MATLAB` o simplemente simulaba algunos datos en `R` y lo hacía de la siguiente manera:


```r
library(ggplot2)

df <- data.frame( x = rnorm(1000))

g1 <- ggplot(df, aes(x)) +
  geom_density(aes(color = "estimada"), key_glyph = "path") + theme_classic()
g1
```

<img src="staticsimula-1.png" width="672" />

Hace poco encontré que la versión `3.3.2` del paquete `ggplot2` permite graficar una función. El usuario puede ingresar la sintaxis de la fórmula o citar el nombre de alguna función de probabilidad conocida. Por ejemplo, en el caso anterior se agregaría la distribución teórica de la siguiente manera

```r
g2 <- g1 +
      geom_function(aes(color = "teórica"), fun = dnorm)
g2
```

<img src="staticunnamed-chunk-1-1.png" width="672" />

Para dar otro ejemplo, considere una distribución chi-cuadrado con 5 grados de libertad, en este caso se establecen los valores para `x` en el rango de 0 a 30. Adicionalmente, se debe agregar una tilde (`~`) después del igual (`=`) y la variable debe estar antecedida por un punto `.x`.


```r
ggplot() +
  xlim(0, 30) +
  geom_function(fun =~ dchisq(.x, df = 5)) + theme_classic()
```

<img src="staticunnamed-chunk-2-1.png" width="672" />

Finalmente, usted puede escribir la sintaxis de cualquier función, si lo prefiere puede usar directamente la fdp, así:


```r
ggplot() +
   xlim(-3, 3) +
   geom_function(
     aes(color = "Normal"),
     fun =~ 1/sqrt(2 * pi) * exp(-.x^2/2)
     ) +
   geom_function(
     aes(color = "Laplace"),
     fun =~ 1/2 * exp(-abs(.x))
   ) + theme_classic() +
  ylab("f(x)") + theme(legend.title = element_blank())
```

<img src="staticunnamed-chunk-3-1.png" width="672" />

Por supuesto, puede usarlo en casos que no tienen que ver con probabilidad


```r
ggplot() +
  xlim(-10, 10) +
  geom_function(aes(color = "lineal"),
    fun =~ 3*.x + 1 
    ) +
  geom_function(aes(color = "cuadrática"),
    fun =~ 3*.x^2 + .x + 1             
    ) + ylab("f(x)") + theme_classic()
```

<img src="staticunnamed-chunk-4-1.png" width="672" />

