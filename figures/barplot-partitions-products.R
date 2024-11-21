source("./figures/defaults.R")

df <- data.frame(group = factor(c("A", "A", "A", "B", "B", "C", "C", "C")),
                 selection = factor(c(1, 1, 2, 1, 2, 1, 2, 2)),
                 value = c(12, 21, 10, 9, 15, 15, 12, 13))
df2 <- aggregate(value ~ group + selection, data = df, sum)

p <- ggplot(df2, aes(group, y = value, fill = selection)) +
  geom_col(position = position_stack(), col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  guides(fill = "none", count = "none") +
  labs(x = NULL, y = "Sum") +
  clean_theme +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"))

ggsave("./figures/barplot-partitions-products.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
