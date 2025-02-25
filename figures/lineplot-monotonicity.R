source("./figures/defaults.R")

set.seed(1234)
x <- cumsum(rnorm(4))
y <- cumsum(rnorm(4))
col <- factor(1:3)

df <- data.frame(x = x[-length(x)], y = y[-length(x)],
                 xend = x[-1], yend = y[-1], col)
df2 <- data.frame(x = x[1], y = y[1], xend = x[length(x)], yend = y[length(x)])

library(ggplot2)

arr <- arrow(length = unit(0.05, "inches"), type = "closed")

p <- ggplot(df, aes(x, y, xend = xend, yend = yend, group = NA)) +
  geom_segment(data = df2, arrow = arr, lwd = 1, col = "grey60", lty = "dashed") +
  geom_segment(aes(col = col), arrow = arr) +
  scale_colour_manual(values = pal_dark_3) +
  scale_x_continuous(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  labs(x = NULL, y = NULL) +
  guides(col = "none")

ggsave("./figures/lineplot-monotonicity.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")


