plotBLB <- function(x, dim=c(1, 2), col.ind = "#E7B800", col.var="#00AFBB",
                    label.ind = FALSE, draw = c("biplot","ind","var"), titles = NULL,
                    ellipses = FALSE, endsegm = 0.75, supvar = NULL, legendt = "no title"){
  
  EspA <- x$Ahat
  EspB <- x$Bhat
  
  k <- ncol(EspA)
  grap <- match.arg(draw[1], c("ind","var","biplot"))
  
  #######.... Markers row
  EspB$x.50 = (-EspB$bb0*EspB$bb1) / rowSums(EspB[,c("bb1", "bb2")]*EspB[,c("bb1", "bb2")])
  EspB$y.50 = (-EspB$bb0*EspB$bb2) / rowSums(EspB[,c("bb1", "bb2")]*EspB[,c("bb1", "bb2")])
  
  EspB$x.75 = (log(endsegm/(1-endsegm))-EspB$bb0)*EspB$bb1 / rowSums(EspB[,c("bb1", "bb2")]*EspB[,c("bb1", "bb2")])
  EspB$y.75 = (log(endsegm/(1-endsegm))-EspB$bb0)*EspB$bb2 / rowSums(EspB[,c("bb1", "bb2")]*EspB[,c("bb1", "bb2")])
  
  colnames(EspA) <- c(paste0("Dim", seq(1,k,1)))
  
  if(ellipses){
    min.plot <- floor(min(min(x$Ellip$Dimb1), min(x$Ellip$Dimb2)))
    max.plot <- ceiling(max(max(x$Ellip$Dimb1), max(x$Ellip$Dimb2)))
  }else{
    min.plot <- floor(min(min(EspA$Dim1), min(EspA$Dim2)))
    max.plot <- ceiling(max(max(EspA$Dim1), max(EspA$Dim2)))
  }
  
  if(x$method == "CG") subt <- "Estimation with Conjugate Gradient"
  if(x$method != "CG") subt <- paste0("Estimation with ", x$method, " algorithm")
  
  if(grap=="ind"){
    
    if (is.null(titles)) titulo <- "Individuals plot"
    if (!is.null(titles)) titulo <- titles
    
    g <-  ggplot() +
      geom_point(data=EspA, aes(x=Dim1, y=Dim2), colour=col.ind, size = 2, shape=17)+
      geom_vline(xintercept = 0, color = "black", linetype = 2) +
      geom_hline(yintercept = 0, color = "black", linetype = 2)  +
      xlab("Dimension 1") + ylab("Dimension 2") +
      geom_text_repel(data=EspA, aes(x=Dim1, y=Dim2, label = rownames(EspA)), size=3.5, segment.color = "grey50") +
      xlim(min.plot, max.plot) + ylim(-min.plot, max.plot) +
      theme_bw() +
      theme(axis.text = element_text(face = "bold"), legend.position = "none") +
      labs(title = titulo,
           subtitle = subt,
           caption = Sys.Date()) +
      theme(plot.title = element_text(hjust = 0.5), plot.subtitle =  element_text(hjust = 0.5))
  }
  
  min.plot2 <- floor(min(min(EspB$x.50), min(EspB$x.75), min(EspB$y.50), min(EspB$y.75)))
  max.plot2 <- ceiling(max(max(EspB$x.50), max(EspB$x.75), max(EspB$y.50), max(EspB$y.75)))
  limit2 <- max(abs(min.plot2), abs(max.plot2))
  
  if(grap == "var"){
    
    if (is.null(titles)) titulo <- "Variables plot"
    if (!is.null(titles)) titulo <- titles
    
    g <- ggplot() +
      geom_segment(data=EspB, aes(x=x.50, y=y.50, xend=x.75, yend=y.75), arrow=arrow(angle=20,type="closed",ends="last", length=unit(0.3,"cm")), colour = col.var, show.legend=FALSE) +
      geom_text_repel(data=EspB, aes(x=x.75, y=y.75, label = rownames(EspB),
                                     angle = (180/pi) * atan(y.75/x.75), hjust = (1 - 2 * sign(x.75))/ 2),
                      size=3, segment.color = "grey50", vjust=0) +
      xlab("Dimension 1") + ylab("Dimension 2") +
      xlim(min.plot2, max.plot2) + ylim(min.plot2, max.plot2) +
      geom_vline(xintercept = 0, color = "black", linetype = 2) +
      geom_hline(yintercept = 0, color = "black", linetype = 2)  +
      theme_bw() +
      theme(axis.text = element_text(face = "bold"), legend.position = "none") +
      labs(title = titulo,
           subtitle = subt,
           caption = Sys.Date()) +
      theme(plot.title = element_text(hjust = 0.5), plot.subtitle =  element_text(hjust = 0.5))
    
  }
  
  min.plot3 <-  min(min.plot, min.plot2)
  max.plot3 <-  max(max.plot, max.plot2)
  limit3 <- max(abs(min.plot3), abs(max.plot3))
  
  if(grap == "biplot"){
    if (is.null(titles)) titulo <- "Bootstrap Binary Logistic Biplot"
    if (!is.null(titles)) titulo <- titles
    
    g <- ggplot() +
      geom_point(data=EspA, aes(x=Dim1, y=Dim2, colour=col.ind), size = 2, shape=17)+
      geom_segment(data=EspB, aes(x=x.50, y=y.50, xend=x.75, yend=y.75), arrow=arrow(angle=20,type="closed",ends="last", length=unit(0.3,"cm")), colour = col.var, show.legend=FALSE) +
      geom_text_repel(data=EspB, aes(x=x.75, y=y.75, label = rownames(EspB),
                                     angle = (180/pi) * atan(y.75/x.75), hjust = (1 - 2 * sign(x.75))/ 2),
                      size=3, segment.color = "grey50", vjust=0) +
      geom_vline(xintercept = 0, color = "black", linetype = 2) +
      geom_hline(yintercept = 0, color = "black", linetype = 2) +
      xlab("Dimension 1") + ylab("Dimension 2") +
      xlim(min.plot3, max.plot3) + ylim(min.plot3, max.plot3) +
      theme_bw() +
      theme(axis.text = element_text(face = "bold")) +
      labs(title = titulo,
           subtitle = subt,
           caption = Sys.Date()) +
      guides(fill=guide_legend(title=legendt)) +
      theme(plot.title = element_text(hjust = 0.5), plot.subtitle =  element_text(hjust = 0.5))
    
  
    if(label.ind){
      g <- g +
        geom_text_repel(data=EspA, aes(x=Dim1, y=Dim2, label = rownames(EspA)), size=3.5, segment.color = "grey50")
    }
  }
  
  if(ellipses){
    g <- g +
      geom_point(data=x$Ellip, aes(x=Dimb1, y=Dimb2, group=ind), size=0.001, colour="lightgray", shape=20)
  }
  
  return(g)
}
