using Unitful
using Unitful: Velocity, Mass, BField, Density, Charge, Energy
using UnitfulAstro

gyroradius(B::BField, mass::Mass, q::Charge, Vperp::Velocity) =
    upreferred(abs(mass * Vperp / (q * B)))

gyroradius(B::BField, E::Energy; m = Unitful.mp, q = Unitful.q) = gyroradius(B, m, q, velocity(E; m))
