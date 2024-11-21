source("./figures/defaults.R")
library(dplyr)

df <- data.frame(group = factor(c("A", "A", "A", "B", "B", "C", "C", "C")),
                 selection = factor(c(1, 1, 2, 1, 2, 1, 2, 2)),
                 value = c(12, 21, 10, 9, 15, 15, 12, 13))
df2 <- aggregate(value ~ group + selection, data = df, sum)

df_spine1 <- df |>
  group_by(group) |>
  summarize(sum = sum(value)) |>
  ungroup() |>
  mutate(left = cumsum(lag(sum, default = 0)), right = cumsum(sum),
         position = (left + right) / 2)

df_spine2 <- df |>
  group_by(group, selection) |>
  summarize(sum_prod = sum(value)) |>
  left_join(df_spine1, by = "group") |>
  mutate(prop = sum_prod / sum) |>
  group_by(group) |>
  mutate(prop_cum = cumsum(prop))

# Need to reorder the rows to make ggplot2 layer the bars in the right order
df_spine2 <- df_spine2[c(2 * 0:2 + 2, 2 * 0:2 + 1), ]

p1 <- ggplot(df2, aes(group, y = value, fill = selection)) +
  geom_col(position = position_stack(), col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  guides(fill = "none", count = "none") +
  labs(x = NULL, y = "Sum") +
  clean_theme +
  theme(plot.margin = unit(c(0, 0.25, 0, 0), units = "cm"))

p2 <- ggplot(df_spine2, aes(position, prop_cum, width = sum, fill = selection)) +
  geom_bar(stat = "identity", position = "identity", col = "white") +
  scale_x_continuous(breaks = df_spine1$position, labels = df_spine1$group) +
  scale_fill_manual(values = pal_dark_3[2:1]) +
  labs(x = NULL, y = "Proportion") +
  guides(fill = "none") +
  clean_theme +
  theme(plot.margin = unit(c(0, 0, 0, 0.25), units = "cm"))

p <- p1 + p2

ggsave("./figures/barplot-spineplot.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
