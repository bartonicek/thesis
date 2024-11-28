source("./figures/defaults.R")

climbers <- read.csv("./data/climbers.csv")
climbers$count <- 1
climbers2 <- aggregate(count ~ country + gender, sum, data = climbers)
levs <- names(table(climbers$country))[order(table(climbers$country))]
climbers2$country <- factor(climbers2$country, levs)

p <- ggplot(climbers2, aes(country, count, fill = gender)) +
  geom_bar(stat = "identity", col = "white") +
  scale_fill_manual(values = pal_dark_3[2:1]) +
  labs(x = "Country", y = "# of climbers", fill = "Gender") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.875))

ggsave("./figures/grammar-barplot-counts.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

