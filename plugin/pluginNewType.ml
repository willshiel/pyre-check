(** Copyright (c) 2016-present, Facebook, Inc.

    This source code is licensed under the MIT license found in the
    LICENSE file in the root directory of this source tree. *)

open Core

open Ast
open Expression
open Statement


let transform_ast ({ Source.statements; _ } as source) =
  let expand_new_type ({ Node.location; value } as statement) =
    let value =
      match value with
      | Assign {
          Assign.value =
            Some {
              Node.value =
                Access [
                  { Node.value = Access.Identifier typing; _ };
                  { Node.value = Access.Identifier new_type; _ };
                  {
                    Node.value =
                      Access.Call [
                        { Argument.value = { Node.value = String name; _ }; _ };
                        {
                          Argument.value = ({ Node.value = Access _; _ } as base);
                          _;
                        } as base_argument;
                      ];
                    _;
                  };
                ];
              _;
            };
          _;
        } when Identifier.show typing = "typing" && Identifier.show new_type = "NewType" ->
          let name = Access.create name in
          let constructor =
            Define {
              Define.name = [
                Access.identifier ~location (Identifier.create "__init__")
              ];
              parameters = [
                Parameter.create ~location ~name:(Identifier.create "self") ();
                Parameter.create ~location ~annotation:base ~name:(Identifier.create "input") ();
              ];
              body = [Node.create Pass ~location];
              decorators = [];
              docstring = None;
              return_annotation = None;
              async = false;
              generated = false;
              parent = Some name;
            }
            |> Node.create ~location
          in
          Class {
            Class.name;
            bases = [base_argument];
            body = [constructor];
            decorators = [];
            docstring = None;
          }
      | _ ->
          value
    in
    { statement with Node.value }
  in
  { source with Source.statements = List.map statements ~f:expand_new_type }