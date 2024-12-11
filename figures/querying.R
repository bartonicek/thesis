source("./figures/defaults.R")

mtcars$car <- rownames(mtcars)

mtcars$info <- paste0(
  mtcars$car, "\n",
  "Weight: ", mtcars$wt, "\n",
  "Mileage: ", mtcars$mpg, "\n",
  "Cylinders: ", mtcars$cyl
)

xr <- diff(range(mtcars$wt))
yr <- diff(range(mtcars$mpg))

p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(col = pal_dark_3[1]) +
  geom_label(data = mtcars[8, ], aes(label = info),
             fill = "grey90", size = 3, label.padding = unit(0.5, "lines"),
             nudge_x = 0.05 * xr, nudge_y = -0.05 * yr, hjust = 0, vjust = 1) +
  geom_segment(x = 3.19 + 0.045 * xr, y = 24.4 - 0.045 * yr,
               xend = 3.19 + 0.02 * xr, yend = 24.4 - 0.02 * yr,
               arrow = arrow(length = unit(0.05, "in"), type = "closed")) +
  coord_fixed(ratio = 1/6) +
  guides(col = "none") +
  labs(x = "Weight", y = "Mileage") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"))

ggsave("./figures/querying.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

