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

  ggplot2::ggplot(
    data    = x$data,
    mapping = ggplot2::aes(x = date, y = value)
  ) +
    ggplot2::geom_line(colour = "#005B96", linewidth = 0.6) +
    ggplot2::geom_area(fill = "#005B96", alpha = 0.08) +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(suffix = suffix)
    ) +
    ggplot2::labs(
      title    = h$name,
      subtitle = subtitle,
      caption  = caption,
      x        = NULL,
      y        = unit_label
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(colour = "grey40"),
      plot.caption     = ggplot2::element_text(colour = "grey55", size = 8),
      axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )
}
