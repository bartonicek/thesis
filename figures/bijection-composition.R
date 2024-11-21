library(ggplot2)
source("./figures/defaults.R")

normalize <- function(x) (x - min(x)) / (max(x) - min(x))

df <- data.frame(
  x = c(rep(1:3, c(3, 4, 3))),
  y = c(1:3 + 0.5, 1:4, 1:3 + 0.5)
)

arrow_df <- data.frame(
  x = rep(1:2, c(3, 4)) + 0.0125,
  xend = rep(c(2, 3), c(3, 4)) - 0.0125,
  y = c(1:3 + 0.5, 1:4),
  yend = c(c(1, 2, 4), c(1, 2, 2, 3) + 0.5)
)

p <- ggplot(df, aes(x, y)) +
  geom_rect(xmin = 0.8, xmax = 1.2, ymin = 1, ymax = 4, fill = "antiquewhite") +
  geom_rect(xmin = 1.8, xmax = 2.2, ymin = 0.5, ymax = 4.5, fill = "antiquewhite") +
  geom_rect(xmin = 2.8, xmax = 3.2, ymin = 1, ymax = 4, fill = "antiquewhite") +
  geom_point(size = 5, col = "indianred") +
  geom_segment(data = arrow_df, aes(x = x, xend = xend, y = y, yend = yend),
               arrow = arrow(angle = 30, length = unit(0.025, "npc")),
               col = "steelblue") +
  geom_text(x = 1.5, y = 2.5, label = "f") +
  geom_text(x = 2.5, y = 2.5, label = "g") +
  scale_x_continuous(limits = c(0.5, 3.5)) +
  scale_y_continuous(limits = c(0.5, 4.5)) +
  clean_theme +
  theme(panel.border = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank())

ggsave("./figures/bijection-composition.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
