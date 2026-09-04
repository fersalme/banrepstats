#' Plot a Banrep series
#'
#' @param x A data.table returned by `fetch_banrep()`/`banrep_data()`.
#' @param ... Further arguments passed to methods.
#'
#' @return A ggplot object.
#' @export
series_plot <- function(x, ...) UseMethod("series_plot")

#' @export
series_plot.data.table <- function(x, ...) {
  if (nrow(x) == 0L) {
    stop("No observations available to plot.")
  }

  unidad_label <- if (data.table::uniqueN(x$unidad) == 1L) {
    x$unidad[1]
  } else {
    "Value"
  }

  # Scale break density to the series' actual date span, so short series
  # aren't sparse and long historical series aren't crowded with labels.
  span_days <- as.numeric(diff(range(x$date)))
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

  colores <- rep_len(
    paleta_banrep(c(
      "azul1",
      "rojo1",
      "gris1",
      "dorado1",
      "azul2",
      "verde1",
      "gris2",
      "naranja1",
      "gris3",
      "morado1"
    )),
    data.table::uniqueN(x$id)
  )

  ggplot2::ggplot(
    data = x,
    mapping = ggplot2::aes(x = date, y = value, color = id)
  ) +
    ggplot2::geom_line(linewidth = 0.6) +
    ggplot2::scale_x_date(
      date_breaks = date_breaks,
      date_labels = date_labels
    ) +
    ggplot2::scale_y_continuous(labels = scales::label_number()) +
    ggplot2::scale_color_manual(values = colores) +
    ggplot2::labs(
      x = NULL,
      y = unidad_label,
      color = "Serie",
      caption = "Source : Banco de la Rep\u00fablica - Portal de estad\u00edsticas econ\u00f3micas"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top"
    )
}
