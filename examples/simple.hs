{-# LANGUAGE OverloadedStrings #-}

-- Copyright (C) 2009-2011 John Millikin <jmillikin@gmail.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Main (main) where

import Data.Text
import Data.List (sort)
import DBus.Client.Simple

main :: IO ()
main = do
	client <- connectSession
	
	-- Request a list of connected clients from the bus
	bus <- proxy client "org.freedesktop.DBus" "/org/freedesktop/DBus"
	reply <- call bus "org.freedesktop.DBus" "ListNames" []
	
	-- org.freedesktop.DBus.ListNames returns a single value, which is
	-- a list of names (here represented as [Text])
	let Just names = fromVariant (reply !! 0)
	
	-- Print each name on a line, sorted so reserved names are below
	-- temporary names.
	mapM_ (putStrLn . unpack) (sort names)
