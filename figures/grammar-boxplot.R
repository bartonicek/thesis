source("./figures/defaults.R")

fev <- read.csv("./data/fev.csv")
fev$smoke <- factor(fev$smoke, labels = c("No", "Yes"))

p <- ggplot(fev, aes(smoke, fev, col = smoke, fill = smoke)) +
  geom_point(size = 0, aes(col = smoke), shape = 15) +
  geom_boxplot(col = "black") +
  scale_fill_manual(values = pal_dark_3) +
  scale_colour_manual(values = pal_dark_3) +
  guides(fill = "none", col = guide_legend(override.aes = c(size = 6.5))) +
  labs(x = "Age", y = "Count", col = "Smoker") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.87))

ggsave("./figures/grammar-boxplot.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
