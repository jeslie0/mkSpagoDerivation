module Main where

import Prelude

import Apexcharts (render, createChart)
import Apexcharts.Chart (chart, type')
import Apexcharts.Common (ChartType(..))
import Apexcharts.Series (series,name, data' )
import Apexcharts.Xaxis (xaxis, categories)
import Data.Options ((:=))
import Effect (Effect)

main :: Effect Unit
main = 
    let myChart = (
            chart := (type' := Bar)
            <> series := [
            name := "sales"
            <> data' := [30,40,35,50,49,60,70,91,125]
            ]
            <> xaxis := (
            categories := [1991,1992,1993,1994,1995,1996,1997,1998,1999]
            )
        )
    in createChart "#chart" myChart >>= render
