#import "@preview/peace-of-posters:0.5.6" as pop
#import "@preview/unify:0.7.1": unit


#set page("a0", margin: 1cm, flipped: true)
#pop.set-poster-layout(pop.layout-a0)
#pop.set-theme(pop.uni-fr)
#set text(size: pop.layout-a0.at("body-size"))
#let box-spacing = 1.2em
#set columns(gutter: box-spacing)
#set block(spacing: box-spacing)
#pop.update-poster-layout(spacing: box-spacing)

#pop.title-box(
  "Energetic particle transport by current sheets in solar wind: determination of diffusion coefficients",
  authors: "Zijin Zhang, Anton V. Artemyev, Vassilis Angelopoulos",
  institutes: "University of California, Los Angeles",
)


Current sheets characterized by large shear angles or relatively
small thickness, can effectively scatter energetic particles and
effect transport beyond the conventional diffusion framework.


#columns(3, [
  #pop.column-box(heading: "Introduction")[
  ]

  #colbreak()

  #pop.column-box(heading: "Results")[
    Perpendicular transport induced by current sheets increases much more rapidly with particle energy than parallel transport
  ]

  #pop.column-box(heading: "Equations")[
    #set math.frac(style: "horizontal")

    $D_perp = lim_(t -> infinity) chevron.l Delta bold(r)_perp(t)^2 chevron.r / 2t$

  ]
])
