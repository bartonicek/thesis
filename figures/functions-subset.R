library(ggplot2)
source("./figures/defaults.R")

df <- expand.grid(x = 1:3, y = 1:3)
df$rel <- with(df, round(x / 2 + 0.1) == y)

p <- ggplot(df, aes(x, y, col = factor(rel))) +
  geom_point(size = 15) +
  scale_x_continuous(breaks = 1:3, limits = c(0.5, 3.5)) +
  scale_y_continuous(breaks = 1:3, limits = c(0.5, 3.5)) +
  scale_color_manual(values = c("white", "indianred")) +
  labs(x = "S", y = "T") +
  guides(col = "none") +
  clean_theme +
  theme(panel.background = element_rect(fill = "antiquewhite"),
        panel.border = element_blank(),
        axis.title.y = element_text(angle = 0, vjust = 0.5),
        axis.title = element_text(colour = "grey60"))

ggsave("./figures/functions-subset.png", p, dpi = 300,
       width = def_height, height = def_height, units = "in")
