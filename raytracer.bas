REM SmallBASIC
REM created: 07/11/2023

' smallbasic doesn't seem to have an equivalent to DBL_MAX
' or math.Inf, so we use 2^24 for now
infinity = 16777216

' seed the RNG to get deterministic output
randomize 42

' render settings
aspectRatio = 16.0 / 9.0
imgWidth = 400
samplesPerPixel = 5
maxBounces = 50

func rndRange(start, finish)
  return start + (finish-start) * rnd()
end

func makeVec3(x, y, z)
  local vec = {}
  vec.x = x
  vec.y = y
  vec.z = z
  func neg()
    local newVec = makeVec3(-self.x, -self.y, -self.z)
    return newVec
  end
  vec.neg = @neg
  func unitVec()
    local l = self.length()
    local newVec = self.divScalar(l)
    return newVec
  end
  vec.unitVec = @unitVec
  func lengthSquared()
    return self.x * self.x + self.y * self.y + self.z * self.z
  end
  vec.lengthSquared = @lengthSquared
  func length()
    return sqr(self.lengthSquared())
  end
  vec.length = @length
  func plus(otherVec)
    local newVec = makeVec3(self.x + otherVec.x, self.y + otherVec.y, self.z + otherVec.z)
    return newVec
  end
  vec.plus = @plus
  func minus(otherVec)
    local newVec = makeVec3(self.x - otherVec.x, self.y - otherVec.y, self.z - otherVec.z)
    return newVec
  end
  vec.minus = @minus
  func mul(otherVec)
    local newVec = makeVec3(self.x * otherVec.x, self.y * otherVec.y, self.z * otherVec.z)
    return newVec
  end
  vec.mul = @mul
  func mulScalar(scalar)
    local newVec = makeVec3(self.x * scalar, self.y * scalar, self.z * scalar)
    return newVec
  end
  vec.mulScalar = @mulScalar
  func divScalar(scalar)
    local newVec = makeVec3(self.x / scalar, self.y / scalar, self.z / scalar)
    return newVec
  end
  vec.divScalar = @divScalar
  func dot(otherVec)
    return self.x * otherVec.x + self.y * otherVec.y + self.z * otherVec.z
  end
  vec.dot = @dot
  func cross(otherVec)
    local newVec = makeVec3(self.y * otherVec.z - self.z * otherVec.y, self.z * otherVec.x - self.x * otherVec.z, self.x * otherVec.y - self.y * otherVec.x)
    return newVec
  end
  vec.cross = @cross
  return vec
end

func makeRandVec3(start, finish)
  return makeVec3(rndRange(start, finish), rndRange(start, finish), rndRange(start, finish))
end

func randomInUnitSphere()
  while true
    local p = makeRandVec3(-1, 1)
    if p.lengthSquared() < 1 then
      return p
    endif
  wend
end

func randomOnHemisphere(normal)
  local onSphere = randomInUnitSphere()
  onSphere = onSphere.unitVec()
  if onSphere.dot(normal) > 0 then
    return onSphere
  else
    return onSphere.neg()
  endif
end

func makeRay(origin, direction)
  local ray = {}
  ray.origin = origin
  ray.direction = direction
  func rayAt(t)
    return self.origin.plus(self.direction.mulScalar(t))
  end
  ray.rayAt = @rayAt
  return ray
end

func makeHitRecord()
  local rec = {}
  rec.p = makeVec3(0, 0, 0)
  rec.normal = makeVec3(0, 0, 0)
  rec.t = 0.0
  rec.frontFace = false
  func setFaceNormal(r, outwardNormal)
    local isFront = false
    if r.direction.dot(outwardNormal) < 0 then
      isFront = true
    endif
    self.frontFace = isFront
    if self.frontFace = true then
      self.normal = outwardNormal
    else
      self.normal = outwardNormal.mulScalar(-1)
    endif
  end
  rec.setFaceNormal = @setFaceNormal
  return rec
end

func makeInterval(start, finish)
  local interval = {}
  interval.start = start
  interval.finish = finish
  func contains(x)
    return self.start <= x and x <= self.finish
  end
  interval.contains = @contains
  func surrounds(x)
    return self.start < x and x <= self.finish
  end
  interval.surrounds = @surrounds
  func clamp(x)
    if x < self.start then
      return self.start
    endif
    if x > self.finish then
      return self.finish
    endif
    return x
  end
  interval.clamp = @clamp
  return interval
end
 
emptyInterval = makeInterval(infinity, infinity * -1)
universeInterval = makeInterval(infinity * -1, infinity)

func makeSphere(center, radius)
  local sphere = {}
  sphere.center = center
  sphere.radius = radius
  func hit(r, interval, byref rec)
    local oc = r.origin.minus(self.center)
    local a = r.direction.lengthSquared()
    local halfB = oc.dot(r.direction)
    local c = oc.lengthSquared() - self.radius * self.radius
    local discriminant = (halfB * halfB) - (a * c)
    if discriminant < 0 then
      return false
    endif
    local sqrtD = sqr(discriminant)
    local recRoot = (-halfB - sqrtD) / a
    if interval.surrounds(recRoot) = false then
      recRoot = (-halfB + sqrtD) / a
      if interval.surrounds(recRoot) = false then
        return false
      endif
    endif
    rec.t = recRoot
    rec.p = r.rayAt(rec.t)
    local outwardNormal = rec.p.minus(self.center)
    outwardNormal = outwardNormal.divScalar(self.radius)
    rec.setFaceNormal(r, outwardNormal)
    return true
  end
  sphere.hit = @hit
  return sphere
end

func makeHittableList()
  local hittableList = {}
  hittableList.objects = []
  func addObj(obj)
    append self.objects, obj
  end
  hittableList.addObj = @addObj
  func hit(r, interval, byref rec)
    local tempRec = makeHitRecord()
    local hitAnything = false
    local closestSoFar = interval.finish
    for i = 0 to len(self.objects) - 1
      local obj = self.objects[i]
      if obj.hit(r, makeInterval(interval.start, closestSoFar), tempRec) then
        hitAnything = true
        closestSoFar = tempRec.t
        rec = tempRec
      endif
    next i
    return hitAnything
  end
  hittableList.hit = @hit
  return hittableList
end

func makePixel(r, g, b)
  local pixel = {}
  pixel.r = r
  pixel.g = g
  pixel.b = b
  func add(p)
    return makePixel(self.r + p.r, self.g + p.g, self.b + p.b)
  end
  pixel.add = @add
  func mulScalar(s)
    return makePixel(self.r * s, self.g * s, self.b *s) 
  end
  pixel.mulScalar = @mulScalar
  func reclamp()
    ' note that we use 255 here instead of the original 255.999
    ' I noticed this was producing blue values of 256 for the
    ' final output of section 4, which GIMP's PPM parser treats
    ' as 0, making the output green, not blue
    local intensity = makeInterval(0.0, 0.999)
    return makePixel(round(intensity.clamp(self.r) * 255), round(intensity.clamp(self.g) * 255), round(intensity.clamp(self.b) * 255))
  end
  pixel.reclamp = @reclamp
  return pixel
end

func makeCamera(aspectRatio, imgWidth, samplesPerPixel, maxBounces)
  local camera = {}
  camera.aspectRatio = aspectRatio
  camera.imgWidth = imgWidth
  camera.samplesPerPixel = samplesPerPixel
  camera.pixelSampleScale = 1 / camera.samplesPerPixel
  camera.maxBounces = maxBounces
  local imgHeight = round(camera.imgWidth / camera.aspectRatio)
  if imgHeight < 1 then
    imgHeight = 1
  endif
  camera.imgHeight = imgHeight
  local focalLength = 1.0
  local viewportHeight = 2.0
  local viewportWidth = viewportHeight * (camera.imgWidth / camera.imgHeight)
  camera.center = makeVec3(0.0, 0.0, 0.0)
  
  local viewportU = makeVec3(viewportWidth, 0.0, 0.0)
  viewportV = makeVec3(0.0, -viewportHeight, 0.0)
  
  camera.pixelDeltaU = viewportU.divScalar(camera.imgWidth)
  camera.pixelDeltaV = viewportV.divScalar(camera.imgHeight)
  
  local viewportUpperLeft = camera.center.minus(makeVec3(0.0, 0.0, focalLength))
  viewportUpperLeft = viewportUpperLeft.minus(viewportU.divScalar(2.0))
  viewportUpperLeft = viewportUpperLeft.minus(viewportV.divScalar(2.0))
  
  camera.pixel00Loc = viewportUpperLeft.plus(pixelDeltaU.plus(pixelDeltaV).mulScalar(0.5))
  
  func rayColor(ray, bouncesLeft, world)
    if bouncesLeft <= 0 then
      return makePixel(0, 0, 0)
    endif
    local hitRecord = makeHitRecord()
    if world.hit(ray, makeInterval(0.001, infinity), hitRecord) = true then
      local direction = randomOnHemisphere(hitRecord.normal)
      local hitColor = makeVec3(0.5, 0.5, 0.5)
      local bounceColor = self.rayColor(makeRay(hitRecord.p, direction), bouncesLeft-1, world)
      ' TODO: add mul to pixel implementation to remove the need to call makeVec3
      hitColor = hitColor.mul(makeVec3(bounceColor.r, bounceColor.g, bounceColor.b))
      return makePixel(hitColor.x, hitColor.y, hitColor.z)
    endif
    local unitDirection = ray.direction.unitVec()
    local a = 0.5 * (unitDirection.y + 1.0)
    ' local ... = makeVec3(...).mulScalar() seems to be invalid
    ' smallbasic, so unfortunately we have to be a lot more
    ' verbose than the c++ original here
    local vp = makeVec3(1.0, 1.0, 1.0)
    vp = vp.mulScalar(1.0 - a)
    local vp2 = makeVec3(0.5, 0.7, 1.0)
    vp2 = vp2.mulScalar(a)
    vp = vp.plus(vp2)
    return makePixel(vp.x, vp.y, vp.z)
  end
  camera.rayColor = @rayColor
  func render(world)
    local dimensions = {}
    dimensions.x = self.imgWidth
    dimensions.y = self.imgHeight
    dim imgData
    for y = 0 to dimensions.y - 1
      ' status update every 10 lines (next best thing since smallbasic seems
      ' to lack a \r equivalent)
      if (dimensions.y - y) % 10 = 0 then
        print "scanlines remaining: "; dimensions.y - y
      endif
      for x = 0 to dimensions.x - 1
        local c = makePixel(0, 0, 0)
        for s = 0 to self.samplesPerPixel - 1
          local r = self.getSampleRay(x, y)
          local sample = self.rayColor(r, self.maxBounces, world)
          c = c.add(sample)
        next s
        c = c.mulScalar(self.pixelSampleScale)
        c = c.reclamp()
        append imgData, c
      next x
    next y
    return imgData
  end
  camera.render = @render
  func getSampleRay(x, y)
    local offset = makeVec3(rnd() - 0.5, rnd() - 0.5, 0)
    local deltaUOffset = self.pixelDeltaU.mulScalar(offset.x + x)
    local deltaVOffset = self.pixelDeltaV.mulScalar(offset.y + y)
    local pixelSample = self.pixel00Loc.plus(deltaUOffset).plus(deltaVOffset)
    local rayDirection = pixelSample.minus(self.center)
    return makeRay(self.center, rayDirection)
  end
  camera.getSampleRay = @getSampleRay
  return camera
end

func writePPMImage(imgPath, imgWidth, imgHeight, imgData)
  local imgFile = freefile()
  open imgPath for output as #imgFile
  ' print PPM header
  print #imgFile, "P3"
  print #imgFile, imgWidth; " "; imgHeight
  print #imgFile, 255
  ' print image data
  for i = 0 to len(imgData) - 1
    print #imgFile, imgData[i].r; " "; imgData[i].g; " "; imgData[i].b
    ' print progress in 10-percent intervals
    if (i + 1) % floor(len(imgData) / 10) = 0 then
      print "<writing ppm> ("; round((i + 1) / len(imgData) * 100); "% complete)"
    endif
  next i
  close #imgFile
end

world = makeHittableList()
mainSphere = makeSphere(makeVec3(0, 0, -1), 0.5)
append world.objects, mainSphere
ground = makeSphere(makeVec3(0, -100.5, -1), 100)
append world.objects, ground

preRenderTicks = ticks()
camera = makeCamera(aspectRatio, imgWidth, samplesPerPixel, maxBounces)
imgData = camera.render(world)
writePPMImage("output.ppm", camera.imgWidth, camera.imgHeight, imgData)
postRenderTicks = ticks()
print "render completed in: "; (postRenderTicks - preRenderTicks) / 1000; " seconds"