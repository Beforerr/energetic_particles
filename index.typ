// Some definitions presupposed by pandoc's typst output.
#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  title: [Energetic Particle Transport in Solar Wind Current Sheets],
  abstract: [Traditional understandings of heliospheric particle transport often rely on simplified turbulence models, neglecting coherent structures. Here, we demonstrate that interactions with solar wind current sheets drive a distinct regime of energetic particle transport. Using test-particle simulations based on heliospheric observations, we show that current sheets induce non-adiabatic scattering and rapid cross-field diffusion. We find that perpendicular diffusion scales with energy significantly faster than parallel diffusion, causing the ratio $D_perp \/ D_parallel$ to exceed standard predictions at high energies. This provides a mechanism for the rapid cross-field transport required to explain the broad spatial extent of solar energetic particle events observed in the inner heliosphere.

],
  abstract-title: "Abstract",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

The transport of energetic particles (EP) in the heliosphere is strongly influenced by the turbulent magnetic field @pucciEnergeticParticleTransport2016@kleinAccelerationPropagationSolar2017@engelbrechtTheoryCosmicRay2022@effenbergerOpenIssuesNongaussian2025. Traditionally, the scattering and transport processes have been modeled using a quasi-linear diffusive approach, assuming magnetic field fluctuations possess a broadband, low-amplitude spectrum without detailed internal structure. However, far from being a simple superposition of random fluctuations, solar-wind turbulence comprises a variety of coherent structures---including current sheets, Alfvénic vortices, and flux ropes @liEffectCurrentSheets2011@perroneCoherentEventsIon2020@khabarovaCurrentSheetsPlasmoids2021@pezziCurrentSheetsPlasmoids2021---arising from nonlinear energy cascade processes @degiorgioCoherentStructureFormation2017.
Understanding particle interaction with these coherent structures @qinEffectFluxTubes2008@zelenyiChargedParticleAcceleration2011@trenchiSolarEnergeticParticle2013@malaraChargedparticleChaoticDynamics2021@malaraEnergeticParticleDynamics2023 is essential for clarifying the mechanisms governing particle transport in the heliosphere. Building on our previous investigation of pitch-angle scattering by solar wind current sheets @zhangQuantificationIonScattering2025@artemyevSuperfastIonScattering2020, this work characterizes the parallel and perpendicular transport of particles resulting from interactions with current sheets.

Parallel transport has traditionally been attributed to pitch-angle scattering, modeled as a diffusive process via a pitch-angle diffusion coefficient. However, in the presence of current sheets---specifically when the gyroradius becomes comparable to the local magnetic field curvature radius---the first adiabatic invariant (magnetic moment) may be violated @tennysonChangeAdiabaticInvariant1986@neishtadtMechanismsDestructionAdiabatic2019. This violation can cause significant non-diffusive jumps in pitch angle, leading to rapid mixing that standard diffusive approaches fail to capture.
Regarding perpendicular transport, it is often assumed that field-line random walk dominates cross-field motion in the limit of slowly varying perturbations @shalchiNonlinearCosmicRay2009. While valid where the magnetic field is smooth on scales comparable to energetic particle gyroradii, this assumption likely breaks down near current sheets. Here, the magnetic field is highly inhomogeneous, varying on scales similar to or smaller than the gyroradius. In this regime, guiding center theory is inapplicable; particles become demagnetized and may undergo significant cross-field transport, jumping between magnetic field lines even in the absence of field-line random walks.

In this work, we investigate energetic particle transport driven by interactions with current sheets. By incorporating statistical parameters derived from solar wind observations at 0.1 AU and 1 AU into a realistic current sheet configuration, we analyze the transport process through an ensemble of current sheets and study the long-term behavior of particles across various energies.

Current sheets are meso-scale structures where the magnetic field direction changes significantly from one side to the other. We assume a 1D force-free magnetic field configuration where $upright(bold(B))$ depends only on the $z$ coordinate (the normal direction): $upright(bold(B)) (z) = B [cos theta med upright(bold(e_z)) + sin theta sin phi (z) med upright(bold(e_x)) + sin theta cos phi (z) med upright(bold(e_y))]$.
In this configuration, the total magnetic magnitude $B$ and the normal component $B_z = B cos theta$ remain constant, while the primary component $B_x$ undergoes a reversal. This rotation is prescribed using a hyperbolic tangent profile $phi.alt (z) = beta tanh (z \/ L)$, where $L$ is the thickness and $beta$ is the shear angle. The configuration parameters ($B$, $L$, $theta$, and $beta$) are drawn from observations @zhangEvolutionSolarWind2025 at 1 AU (ARTEMIS @angelopoulosARTEMISMission2011 and Wind @acunaGlobalGeospaceScience1995) and at 0.1 AU (Parker Solar Probe @foxSolarProbeMission2016).

We employ a Monte Carlo method with test-particle simulations to investigate transport through multiple current sheets. Each particle is initialized with a random pitch angle $alpha$ and gyrophase $psi$, traversing a distance $L$ corresponding to the observed spatial separation between neighboring sheets. For simplicity, we assume (1) the current sheets are static during the interaction time; (2) $L$ is a constant, depending only on the heliocentric radial distance, and (3) there is no pitch-angle scattering during transit. Consequently, particles transit the distance $L$ in time $t_L = L \/ lr(|v_parallel|)$ before encountering a current sheet.

We model the interaction by numerically solving the simplified Newton-Lorentz equation $d upright(bold(p)) \/ d t = q upright(bold(v)) times upright(bold(B))$, neglecting large-scale electric fields and explicit time dependence, as energetic particle velocities are high compared to the Alfvén speed. Magnetic field parameters for each interaction are randomly sampled from the observed distributions.

In each test-particle simulation, particles are launched far from the sheet center with a random gyrophase $psi in \[ 0 \, 2 pi \)$ and traced until they exit the interaction region. We record the change in pitch angle and calculate the net perpendicular guiding-center displacement $Delta 𝐫_perp$ between the entry and exit points. Trapping time within the current sheet is estimated by subtracting the ballistic transit time (approach to and departure from the current sheet assuming no pitch-angle scattering) from the total simulation time. For most interactions, trapping persists for several gyroperiods. Since the background magnetic field orientation could vary slowly between sheets, we treat the orientation of individual current sheets as random variables. The accumulated perpendicular displacement after multiple interactions is modeled as a sequence of random rotations $upright(bold(R))$ applied to individual displacement vectors: $Delta upright(bold(r))_perp = sum_i upright(bold(R))_i dot.op Delta upright(bold(r))_(perp \, i)$. The total parallel displacement is simply the sum of the parallel displacement between sheets: $Delta z = sum_i upright("sgn") (mu_i) dot.op L$.

We propagate an ensemble of particles and compute $angle.l Delta z^2 angle.r$ and $angle.l Delta upright(bold(r))_perp^2 angle.r$ by interpolating trajectories at successive time steps. Both parallel and perpendicular transport exhibit diffusive behavior, growing linearly with time in the asymptotic limit. We calculate the diffusion coefficients $D_parallel = lim_(t arrow.r oo) angle.l Delta z (t)^2 angle.r \/ 2 t$ and $D_perp = lim_(t arrow.r oo) angle.l Delta upright(bold(r))_perp (t)^2 angle.r \/ 2 t$ using 512 particles at late times ($t = 2 times 10^3$ s).

The main findings are presented in #ref(<fig-trajs>, supplement: [Figure]) and #ref(<fig-diffusion>, supplement: [Figure]). #ref(<fig-trajs>, supplement: [Figure]) displays the state trajectories for 1-MeV particles interacting with near-Earth current sheets.

#figure([
#box(image("figures/trajectories_1MeV.pdf"))
], caption: figure.caption(
position: bottom, 
[
Parallel and perpendicular displacements for 1-MeV particles interacting with near-Earth current sheets. Gray lines: individual particle trajectories; Blue line: standard deviation of the ensemble; Black line: a representative trajectory.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-trajs>


While most trajectories show a linear increase in parallel displacement with minor perpendicular fluctuations, specific magnetic configurations induce substantial discontinuities in the particle state. These include large pitch-angle jumps, which may lead to reflection, and abrupt cross-field displacements. While these jumps may occur independently, the stochastic accumulation leads to diffusive macroscopic transport, causing particles to disperse along the field lines and diverge from their initial field lines.

#ref(<fig-diffusion>, supplement: [Figure]) summarizes the diffusion coefficients as functions of particle energy for 1 AU and 0.1 AU environments, comparing our results with quasi-linear theory predictions derived from measured magnetic turbulence power spectra @chenParallelDiffusionCoefficient2024.

#figure([
#box(image("figures/diffusion.pdf"))
], caption: figure.caption(
position: bottom, 
[
Diffusion coefficients vs.~particle energy at 1 AU and 0.1 AU. (a) Parallel diffusion; (b) Perpendicular diffusion; (c) Ratio of perpendicular to parallel diffusion.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-diffusion>


A key finding is that perpendicular transport induced by current sheets increases much more rapidly with particle energy than parallel transport. The ratio $D_perp \/ D_parallel$ can exceed the typically assumed $2 % - 4 %$ for high-energy particles ($> 1$ MeV at 1 AU). This strong energy dependence differs from earlier studies suggesting the ratio is independent of energy @shalchiPerpendicularDiffusionEnergetic2021 and intermittency @pucciEnergeticParticleTransport2016. Our results offer a potential explanation for observational puzzles such as the large longitudinal and latitudinal extent of solar energetic particle (SEP) events detected by widely separated spacecraft @zhangPropagationSolarEnergetic2009@larioSolarEnergeticParticle2014@desaiLargeGradualSolar2016.

In summary, this study demonstrates that interactions with current sheets are a significant driver of energetic-particle transport. Our model is necessarily simplified. For example, we do not include realistic waiting-time distributions between current-sheet, which may give rise to anomalous transport regimes @giacaloneAnomalousCosmicRays2022@effenbergerOpenIssuesNongaussian2025. We also neglect the systematic evolution of the heliospheric magnetic field with radial distance and the resulting changes in current-sheet configurations experienced by propagating particles. Moreover, the heliosphere is inherently three-dimensional @effenbergerDiffusionApproximationTelegraph2014, and actual current sheets exhibit complex three-dimensional structures that are not captured in our present modeling framework.
Despite these simplifications, our results provide some of the first quantitative evidence that current sheets may play a substantial role in modulating energetic-particle transport. Because current sheets constitute a major component of solar-wind turbulence @malandrakiCurrentSheetsMagnetic2019 and contribute significantly to magnetic field fluctuations @borovskyContributionStrongDiscontinuities2010, accounting for their effects is essential for developing accurate transport models @whitmanReviewSolarEnergetic2023. Future work should therefore aim to incorporate more realistic descriptions of current-sheet geometries and dynamics to better quantify and constrain their influence on particle propagation.

#bibliography("files/bibliography/research.bib")

