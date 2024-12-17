
df <- read.csv("./data/dlouhodoba-pece.csv")

column_names <- c(
  "rok" = "year",
  "kraj_nuts_kod" = "region_code",
  "kraj_nazev" = "region",
  "pohlavi" = "sex",
  "zakladni_diagnoza" = "diagnosis",
  "ukonceni" = "reason_for_termination",
  "vekova_kategorie" = "age_category",
  "kategorie_delky_hospitalizace" = "stay_category",
  "obor" = "field",
  "kategorie_pece" = "care_category",
  "pocet_hospitalizaci" = "hospitalizations",
  "delka_hospitalizace" = "days"
)

names(df) <- column_names[names(df)]
df$sex <- c(M = "male", Z = "female")[df$sex]

replace_pairs <- function(x, pattern, replacement) {
  for (i in seq_along(pattern)) {
    x <- gsub(pattern[i], replacement[i], x)
  }
  x
}

df$diagnosis <- replace_pairs(df$diagnosis,
                              c(" a ", " bez ", "Ostatní"),
                              c(" and ", " without ", "other"))
df$diagnosis <- tolower(df$diagnosis)

termination_reasons <- c(
  "Propuštění" = "release",
  "Předčasné ukončení" = "early termination",
  "Přeložen do jiného ZZ" = "transfer to another facility",
  "Úmrtí" = "death",
  "Ostatní" = "other"
)

df$reason_for_termination <- termination_reasons[df$reason_for_termination]

df$stay_category <- c(
  "1.Krátkodobá" = "short-term",
  "2.Střednědobá" = "medium-term",
  "3.Dlouhodobá" = "long-term"
)[df$stay_category]

df$field <- c(
  "Psychiatrie" = "psychiatry",
  "Dětská a dorostová psychiatrie" = "child and adolescent psychiatry",
  "Návykové nemoci" = "addiction treatment",
  "Gerontopsychiatrie" = "geriatric psychiatry"
)[df$field]

df$care_category <- c(
  "Dospělý" = "adult",
  "Dítě" = "child"
)[df$care_category]

df <- data.frame(lapply(df, unname))
write.csv(df, "./data/longterm_care.csv", row.names = FALSE)

