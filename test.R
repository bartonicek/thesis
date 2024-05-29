
library(scales)

p = (f(x) - f(min)) / (f(max) - f(min))
x = f^(1)(p * (f(max) - f(min)) + f(min))

#
# plot(seq(0, 1, length = 100), sqrt(seq(0, 1, length = 100)), type = "l")

lims <- c(3, 10)

expanse_continuous <- function(min, max) {
  list(min = min, max = max)
}

expanse <- expanse_continuous(lims[1], lims[2])
expanse$trans <- function(x)  x^2
expanse$inv <- sqrt

expanse$normalize <- function(x) {
  min <- expanse$min
  max <- expanse$max
  trans <- expanse$trans
  inv <- expanse$inv

  (trans(x) - trans(min)) / (trans(max) - trans(min))
}

expanse$unnormalize <- function(p) {
  min <- expanse$min
  max <- expanse$max
  trans <- expanse$trans
  inv <- expanse$inv

  inv(trans(min) + p * (trans(max) - trans(min)))
}

x <- seq(-100, 100, length = 100)
p <- (x - min(x)) / (max(x) - min(x))

scales_scaled <- cscale(x, area_pal(c(lims[1], lims[2])))
expanse_scaled <- expanse$unnormalize(p)

par(mfrow = c(1, 1))
plot(x, scales_scaled, type = "l")
lines(x, expanse_scaled, col = "red")
points(x, lims[1] + sqrt(seq(0, 1, length = 100)) * (lims[2] - lims[1]))

par(mfrow = c(1, 2))
plot(x, y = rep(1, length(x)), cex = scales_scaled)
plot(x, y = rep(1, length(x)), cex = expanse_scaled, col = "red")

scales_scaled[length(x)] / scales_scaled[length(x) / 2]
expanse_scaled[length(x)] / expanse_scaled[length(x) / 2]

scales_scaled[10] / scales_scaled[5]
expanse_scaled[10] / expanse_scaled[5]

plot(cscale(1:10, area_pal(c(0, 10))))

area_pal()

ggplot(mpg, aes(displ, hwy, size = cty)) +
  geom_point() +
  scale_x_continuous()
