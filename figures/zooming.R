source("./figures/defaults.R")

mtcars$fill <- mtcars$wt > 3 & mtcars$wt < 4.25 &
  mtcars$mpg > 12.5 & mtcars$mpg < 20

px <- ggplot(data.frame()) +
  geom_segment(aes(x = -0.8, y = 0, xend = 0.8, yend = 0),
               arrow = arrow(length = unit(0.05, "inches"), type = "closed")) +
  scale_x_continuous(limits = c(-1, 1)) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void()

p1 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  geom_rect(xmin = 3, ymin = 12.5, xmax = 4.25, ymax = 20,
            fill = NA, col = "grey60", lwd = 0.25, lty = "dashed") +
  guides(col = "none") +
  labs(x = NULL, y = NULL)

p2 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = NULL, y = NULL) +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25), ylim = c(12.5, 20))

p <- p1 + px + p2 + plot_layout(widths = c(1, 1/4, 1))

ggsave("./figures/zooming.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")


