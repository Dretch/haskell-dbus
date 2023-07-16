{-# LANGUAGE OverloadedStrings #-}

-- Copyright (C) 2012 John Millikin <john@john-millikin.com>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

module DBusTests.Wire (test_Wire) where

import Data.Either
import System.Posix.Types (Fd(..))
import Test.Tasty
import Test.Tasty.HUnit

import qualified Data.ByteString.Char8 ()

import DBus
import DBus.Internal.Message
import DBus.Internal.Types
import DBus.Internal.Wire

import DBusTests.Util

test_Wire :: TestTree
test_Wire = testGroup "Wire" $
    [ test_Unmarshal
    , test_FileDescriptors
    ]

test_Unmarshal :: TestTree
test_Unmarshal = testGroup "unmarshal"
    [ test_UnmarshalUnexpectedEof
    ]

test_UnmarshalUnexpectedEof :: TestTree
test_UnmarshalUnexpectedEof = testCase "unexpected-eof" $ do
    let unmarshaled = unmarshal "0" []
    assertBool "invalid unmarshalled parse" (isLeft unmarshaled)

    let Left err = unmarshaled
    unmarshalErrorMessage err
        @=? "Unexpected end of input while parsing message header."

test_FileDescriptors :: TestTree
test_FileDescriptors = testGroup "Unix File Descriptor Passing" $
    [ test_FileDescriptors_Marshal
    , test_FileDescriptors_UnmarshalHeaderError
    ]

test_FileDescriptors_Marshal :: TestTree
test_FileDescriptors_Marshal = testCaseSteps "(un)marshal round trip" $ \step -> do
    let baseMsg = methodCall "/" "org.example.iface" "Foo"
    
    step "marshal"
    let msg = baseMsg { methodCallBody = [toVariant [Fd 4, Fd 3, Fd 4, Fd 7, Fd 3]] }
        Right (bytes, fds) = marshal LittleEndian firstSerial msg
    fds @?= [Fd 4, Fd 3, Fd 7]

    step "unmarshal"
    let Right call = unmarshal bytes [Fd 10, Fd 11, Fd 12]
    receivedMessageBody call @?= [toVariant [Fd 10, Fd 11, Fd 10, Fd 12, Fd 11]]

test_FileDescriptors_UnmarshalHeaderError :: TestTree
test_FileDescriptors_UnmarshalHeaderError = testCase "UnixFdHeader mismatch" $ do
    let msg = (methodCall "/" "org.example.iface" "Foo")
            { methodCallBody = [toVariant [Fd 5, Fd 6, Fd 7]] }
        Right (bytes, fds) = marshal LittleEndian firstSerial msg
        
    let Left err = unmarshal bytes [Fd 5, Fd 6]
    unmarshalErrorMessage err @?= "File descriptor count in message header (3)"
      <> " does not match the number of file descriptors received from the socket (2)."
