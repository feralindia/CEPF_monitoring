## Calculate FAPAR for entire region
## Resources: http://fapar.jrc.ec.europa.eu/Home.php,
## 


## Get albedo

    i.albedo -l --overwrite input=b1,b2,b3,b4,b5,b7 output=albedo


## Get net radiation:

r.sun elevation=ASTERdem@terrain aspect=ASTERaspect@terrain slope=ASTERslope@terrain linke_value=2.0 albedo=albedo.E71430531999_ond@pet incidout=out beam_rad=beam diff_rad=diffuse refl_rad=reflected day=<required>

    netrad r.mapcalc "NSR = 0.0036 * (beam + diffuse + reflected)"

