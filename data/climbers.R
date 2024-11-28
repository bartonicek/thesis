
library(rvest)

mens_url <- "https://olympics.com/en/paris-2024/results/sport-climbing/men-s-boulder-and-lead/sfnl000200--"
womens_url <- "https://olympics.com/en/paris-2024/results/sport-climbing/women-s-boulder-and-lead/sfnl000200--"

womens_html <- read_html_live(womens_url)
womens_tab <- womens_html |> html_table()
womens_tab <- womens_tab[[1]]

mens_html <- read_html_live(mens_url)
mens_tab <- mens_html |> html_table()
mens_tab <- mens_tab[[1]]

womens_tab$gender <- "female"
mens_tab$gender <- "male"

climbers <- rbind(mens_tab, womens_tab)
climbers <- climbers[, -c(2, 5:6)]

names(climbers) <- c("rank", "country", "name",
                     "boulder", "lead", "total",
                     "qualified", "gender")

format_points <- function(x) {
  as.numeric(gsub("\\(\\d+\\)$", "", x))
}

climbers$qualified <- climbers$qualified == "Q Qualified"
climbers$boulder <- format_points(climbers$boulder)
climbers$lead <- format_points(climbers$lead)

name_pattern <- "[A-Z][a-z]+ [A-Z]+([ -][A-Z]+)?"
climbers$name <- stringr::str_extract(sub(" \\w$", "", climbers$name), name_pattern)

write.csv(climbers, "./data/climbers.csv", row.names = FALSE)
