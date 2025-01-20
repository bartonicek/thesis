source("./figures/defaults.R")

df <- mtcars
df$am <- factor(df$am)
df$cyl <- factor(df$cyl, labels = c("A", "B", "C"))

p0 <- ggplot() +
  guides(fill = "none") +
  scale_fill_manual(values = pal_dark_3) +
  labs(x = NULL, y = NULL)

set.seed(89719)
mtcars$group1 <- factor(sample(rep(c(0, 1), c(27, 5))))
mtcars$group2 <- factor(sample(rep(c(0, 1), c(17, 15))))
mtcars$group3 <- factor(sample(rep(c(0, 1), c(7, 25))))

plots <- list()
for (i in 1:3) {
  mtcars$group <- mtcars[[paste0("group", i)]]
  plots[[i]] <- p0 +
    geom_bar(data = mtcars, col = "white", mapping = aes(cyl, fill = group))
  plots[[3 + i]] <- plot_spacer()
  plots[[6 + i]] <- p0 +
    geom_bar(data = mtcars, col = "white", mapping = aes(cyl, fill = group),
             position = "dodge")
}

p <- wrap_plots(plots, nrow = 3, heights = c(1, 0.1, 1))

ggsave("./figures/stacking-vs-dodging.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
