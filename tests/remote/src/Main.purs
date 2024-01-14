module Main where

import Prelude

import Effect (Effect)
import Effect.Console (logShow)
import FFT

fft = makeFFT 4

main :: Effect Unit
main = do
  logShow $ realTransform fft $ RealArray [1.0,2.0,3.0,4.0]
