source("./figures/defaults.R")

df <- data.frame(x = rep(c("Euthanasia", "Cannabis"), each = 2),
                 y = c(1893290, 979079, 1406973, 1474635),
                 fill = rep(c("For", "Against"), 2))

df$x <- factor(df$x, levels = c("Euthanasia", "Cannabis"))
df$fill <- factor(df$fill, levels = c("For", "Against"))

p <- ggplot(df, aes(x, y, fill = fill)) +
  geom_bar(stat = "identity", col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = NULL, y = "# of votes", fill = "Vote") +
  clean_theme +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"))

ggsave("./figures/referendum-notbijection.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
