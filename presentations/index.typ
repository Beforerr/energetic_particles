#import "@preview/touying:0.6.1": *
#import "@preview/unify:0.7.1": unit
#import themes.university: *

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Energetic Particle Transport in Solar Wind Current Sheets],
  ),
)
// #show: simple-theme.with(aspect-ratio: "16-9")

== Results

#slide(composer: (2fr, 2fr))[
  #set text(13pt)

  - Interactions with solar wind current sheets drive a distinct regime of energetic particle transport.
  - Current sheets induce non-adiabatic scattering and rapid cross-field diffusion

  #figure(
    image("../figures/fig-B_diagram_particle_trajectory.png"),
  )
][
  #set text(16pt)
  #figure(
    image("../figures/trajectories_1MeV.png"),
    caption: [Parallel and perpendicular displacements for 1-MeV particles interacting with near-Earth current sheets. Gray lines: individual particle trajectories; Blue line: standard deviation of the ensemble; Black line: a representative trajectory.],
  )
]

#set text(20pt)

#figure(
  image("../figures/diffusion.pdf"),
  caption: [Diffusion coefficients vs. particle energy at 1 AU and 0.1 AU. (a) Parallel diffusion; (b) Perpendicular diffusion; (c) Ratio of perpendicular to parallel diffusion.],
)
