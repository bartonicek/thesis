source("./figures/defaults.R")
library(patchwork)

label_size <- 8 / .pt

stack <- function(values, fn, initial) {
  values[is.na(values)] <- initial
  for (i in seq_along(values)) values[i] <- fn(values[i - 1], values[i])
  values
}

two_mean <- function(x) (c(0, x[-length(x)]) + x) / 2

format_label <- function(value, symbol) {
  ifelse(is.na(value), value, paste0(symbol, value))
}

or_na <- function(x) ifelse(is.na(x), "NA", x)

group <- factor(rep(c("A", "B"), each = 3))
original_subgroups <- rep(3:1, 2)
original_values <- matrix(c(0.8, 1.2, 1.6, NA, 1.1, 1.5), ncol = 2)

plots <- list()
perms <- list(1:3, c(2, 1, 3), 3:1)

for (i in 1:3) {

  perm <- perms[[i]]
  values <- apply(original_values, 2, function(x) x[perm])
  subgroup <- original_subgroups[perm]

  value <- as.numeric(values)
  value[is.na(value)] <- 0

  sums <- apply(values, 2, function(x) stack(x, sum, 0))
  maximums <- apply(values, 2, function(x) stack(x, max, 0))
  sums_midpoint <- apply(sums, 2, two_mean)
  maximums_midpoint <- apply(maximums, 2, two_mean)

  sums_df <- data.frame(group, subgroup, value,
                        midpoint = as.numeric(sums_midpoint),
                        cum_value = as.numeric(sums))

  maximums_df <- data.frame(group, subgroup, value,
                            midpoint = as.numeric(maximums_midpoint),
                            cum_value = as.numeric(maximums))

  p0 <- ggplot() +
    scale_fill_manual(values = pal_dark_3) +
    guides(fill = "none") +
    labs(x = NULL, y = NULL) +
    theme_bw() +
    theme(
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      plot.title = element_text(size = 12, hjust = 0.1),
      plot.margin = unit(c(0, 0, 0, 0), units = "cm")
    )


  dups <- duplicated(subset(maximums_df, select = c("cum_value")))

  # Need to rearrange for ggplot2 to stack the bars in the correct order
  sums_df <- sums_df[c(3:1, 6:4), ]
  maximums_df <- maximums_df[c(3:1, 6:4), ]

  sums_df <- sums_df[-which(sums_df$value == 0), ]
  maximums_df <- maximums_df[-which(maximums_df$value == 0), ]

  # Remove rows with duplicate values
  last_value <- -Inf
  for (j in rev(seq_len(nrow(maximums_df)))) {
    if (maximums_df$cum_value[j] == last_value) {
      maximums_df <- maximums_df[-j, ]
    }
    last_value <- maximums_df$cum_value[j]
  }

  plots[[3 * i - 2]] <- p0 +
    geom_bar(data = sums_df, aes(group, cum_value,
                                 fill = factor(subgroup)),
             stat = "identity", position = "identity", col = "white") +
    geom_text(data = sums_df, aes(group, midpoint,
                                  label = format_label(value, "+")),
              size = label_size, col = "white")

  plots[[3 * i - 1]] <- plot_spacer()

  plots[[3 * i]] <- p0 +
    geom_bar(data = maximums_df,
             mapping = aes(group, cum_value,
                           fill = factor(subgroup)),
             stat = "identity", position = "identity", col = "white") +
    geom_text(data = maximums_df, aes(group, midpoint,
                                      label = format_label(value, "max\n")),
              size = label_size, col = "white", lineheight = 1)
  }

p <- wrap_plots(plots, nrow = 3, byrow = FALSE,
           heights = c(1, 1/8, 1))

ggsave("./figures/monoids-groups-inverses.png", p, dpi = 300,
       width = def_width, height = 3 / 2 * def_height, units = "in")
