# ── series_plot generic ───────────────────────────────────────────────────────
#' @export
series_plot <- function(x, ...) UseMethod("series_plot")

#' @export
series_plot.banrep_data <- function(x, ...) {
  if (nrow(x$data) == 0L) stop("No observations available to plot.")

  h <- x$metadata$header
  s <- x$metadata$series

  subtitle <- paste(
    Filter(Negate(is.null), list(
      if (!is.null(s$REFERENCE_AREA)) paste("Country:",   s$REFERENCE_AREA),
      if (!is.null(s$FREQ))           paste("Frequency:", s$FREQ),
      if (!is.null(s$UNIT_MEASURE))   paste("Unit:",      s$UNIT_MEASURE)
    )),
    collapse = "  |  "
  )

  caption <- paste0(
    h$sender_name, " (", h$email, ")",
    "  \u2014  Extracted: ", h$extracted
  )

  # Determine y-axis label from unit_measure
  unit_label <- switch(
    s$UNIT_MEASURE %||% "",
    "ER"   = "Effective Rate (%)",
    "PA"   = "Percentage (%)",
    "COP"  = "Colombian Peso (COP)",
    "IX"   = "Index",
    "CRVU" = "COP per UVR",
    "Value"
  )

  suffix <- if (s$UNIT_MEASURE %in% c("ER", "PA")) "%" else ""

  # Scale break density to the series' actual date span, so short series
  # aren't sparse and long historical series aren't crowded with labels.
  span_days <- as.numeric(diff(range(x$data$date)))
  date_breaks <- if (span_days <= 365) {
    "1 month"
  } else if (span_days <= 365 * 3) {
    "3 months"
  } else if (span_days <= 365 * 10) {
    "1 year"
  } else {
    "2 years"
  }
  date_labels <- if (date_breaks %in% c("1 year", "2 years")) "%Y" else "%b %Y"
  
  ggplot2::ggplot(
    data    = x$data,
    mapping = ggplot2::aes(x = date, y = value, color = id)
  ) +
    ggplot2::geom_line(linewidth = 0.6) + 
    ggplot2::scale_x_date(date_breaks = date_breaks, date_labels = date_labels) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(suffix = suffix)
    ) +
    ggplot2::labs(
      title    = h$name,
      subtitle = subtitle,
      caption  = caption,
      x        = NULL,
      y        = unit_label,
      color = "Serie"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(colour = "grey40"),
      plot.caption     = ggplot2::element_text(colour = "grey55", size = 8, hjust = 0),
      axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top"
    )
}
