library(ggplot2)
library(patchwork)
source("./figures/defaults.R")

normalize <- function(x) (x - min(x)) / (max(x) - min(x))

plot_function <- function(mapping, codomain_size = NULL) {

  codomain_size <- ifelse(is.null(codomain_size), max(mapping), codomain_size)

  domain <- 1:length(mapping)
  codomain <- 1:codomain_size

  # Center on the same value
  diff <- mean(domain) - mean(codomain)
  domain <- domain - diff / 2
  codomain <- codomain + diff / 2

  domain <- normalize(domain)
  codomain <- normalize(codomain)

  point_data <- data.frame(x = c(domain, codomain),
                           y = rep(c(1, 0), sapply(list(domain, codomain), length)))
  arrow_data <- data.frame(x = domain, xend = codomain[mapping],
                           y = 1, yend = 0)

  h <- 0.25

  ggplot(point_data, aes(x, y)) +
    geom_rect(aes(xmin = -0.2, xmax = 1.2, ymin = 0 - h / 2, ymax = 0 + h / 2),
              fill = "antiquewhite") +
    geom_rect(aes(xmin = -0.2, xmax = 1.2, ymin = 1 - h / 2, ymax = 1 + h / 2),
              fill = "antiquewhite") +
    geom_text(x = -0.1, y = 1.08, label = "S", size = 2, col = "grey60") +
    geom_text(x = -0.1, y = -0.08, label = "T", size = 2, col = "grey60") +
    geom_point(size = 5, col = "indianred") +
    geom_segment(data = arrow_data, aes(x = x, xend = xend, y = y, yend = yend),
                 arrow = arrow(angle = 30, length = unit(0.025, "npc")),
                 col = "steelblue") +
    scale_x_continuous(limits = c(-0.2, 1.2)) +
    scale_y_continuous(limits = c(-0.2, 1.2)) +
    clean_theme +
    theme(panel.border = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          plot.title = element_text(vjust = -5, hjust = 0.5))
}

p1 <- plot_function(c(1, 2, 1, 3, 4, 4)) + labs(title = "Surjective")
p2 <- plot_function(c(3, 4, 2, 5), 6) + labs(title = "Injective")
p3 <- plot_function(c(4, 2, 6, 3, 1, 5)) + labs(title = "Bijective")

p <- p1 + p2 + p3

ggsave("./figures/functions-types.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
