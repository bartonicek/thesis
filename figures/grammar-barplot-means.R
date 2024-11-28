source("./figures/defaults.R")

climbers <- read.csv("./data/climbers.csv")
climbers2 <- aggregate(total ~ country + gender, mean, data = climbers)
climbers3 <- aggregate(total ~ country, sum, data = climbers2)
climbers3 <- climbers3[order(climbers3$total), ]

climbers2$country <- factor(climbers2$country, climbers3$country)

p <- ggplot(climbers2, aes(country, total, fill = gender)) +
  geom_bar(stat = "identity", col = "white") +
  scale_fill_manual(values = pal_dark_3[2:1]) +
  labs(x = "Country", y = "Average score", fill = "Gender") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.875))

ggsave("./figures/grammar-barplot-means.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

