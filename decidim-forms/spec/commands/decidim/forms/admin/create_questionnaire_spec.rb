# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    module Admin
      describe CreateQuestionnaire do
        let(:current_organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization: current_organization) }
        let(:form_params) do
          {
            "title" => {
              "en" => "Title",
              "ca" => "Title",
              "es" => "Title"
            },
            "tos" => {
              "en" => "<p>TOS</p>",
              "ca" => "<p>TOS</p>",
              "es" => "<p>TOS</p>"
            },
            "description" => {
              "en" => "<p>Content</p>",
              "ca" => "<p>Contingut</p>",
              "es" => "<p>Contenido</p>"
            },
            "questions" => {
              "0" => {
                "body" => {
                  "en" => "First question",
                  "ca" => "Primera pregunta",
                  "es" => "Primera pregunta"
                },
                "position" => "0",
                "question_type" => "short_answer",
                "answer_options" => {}
              },
              "1" => {
                "body" => {
                  "en" => "Second question",
                  "ca" => "Segona pregunta",
                  "es" => "Segunda pregunta"
                },
                "description" => { "en" => "Description" },
                "position" => "1",
                "mandatory" => "1",
                "question_type" => "long_answer",
                "answer_options" => {}
              },
              "2" => {
                "body" => {
                  "en" => "Third question",
                  "ca" => "Tercera pregunta",
                  "es" => "Tercera pregunta"
                },
                "position" => "2",
                "question_type" => "single_option",
                "answer_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First answer",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "0"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second answer",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                }
              },
              "3" => {
                "body" => {
                  "en" => "Fourth question",
                  "ca" => "Quarta pregunta",
                  "es" => "Cuarta pregunta"
                },
                "position" => "3",
                "question_type" => "multiple_option",
                "max_choices" => "2",
                "answer_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First answer",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second answer",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                }
              },
              "4" => {
                "body" => {
                  "en" => "Fifth question",
                  "ca" => "Cinquena pregunta",
                  "es" => "Quinta pregunta"
                },
                "position" => "4",
                "question_type" => "matrix_single",
                "answer_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First answer",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second answer",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                },
                "matrix_rows" => {
                  "0" => {
                    "body" => {
                      "en" => "First row",
                      "ca" => "Primera fila",
                      "es" => "Primera fila"
                    }
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second row",
                      "ca" => "Segona fila",
                      "es" => "Segunda fila"
                    }
                  }
                }
              },
              "5" => {
                "body" => {
                  "en" => "Sixth question",
                  "ca" => "Sisena pregunta",
                  "es" => "Sexta pregunta"
                },
                "position" => "5",
                "question_type" => "matrix_multiple",
                "max_choices" => "2",
                "answer_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First answer",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second answer",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                },
                "matrix_rows" => {
                  "0" => {
                    "body" => {
                      "en" => "First row",
                      "ca" => "Primera fila",
                      "es" => "Primera fila"
                    }
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second row",
                      "ca" => "Segona fila",
                      "es" => "Segunda fila"
                    }
                  }
                }
              }
            }
          }
        end
        let(:form) do
          QuestionnaireForm.from_params(
            questionnaire: form_params
          ).with_context(
            questionnaire_for: current_organization,
            current_organization: current_organization
          )
        end
        let(:command) { described_class.new(form) }

        describe "when the form is invalid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a questionnaire" do
            expect { command.call }.not_to change(Decidim::Forms::Questionnaire, :count)
          end
        end

        describe "when the form is valid" do
          let(:questionnaire) { Decidim::Forms::Questionnaire.last }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates the questionnaire" do
            command.call

            expect(questionnaire.description["en"]).to eq("<p>Content</p>")
            expect(questionnaire.questions.length).to eq(6)

            questionnaire.questions.each_with_index do |question, idx|
              expect(question.body["en"]).to eq(form_params["questions"][idx.to_s]["body"]["en"])
            end

            expect(questionnaire.questions[1]).to be_mandatory
            expect(questionnaire.questions[1].description["en"]).to eq(form_params["questions"]["1"]["description"]["en"])
            expect(questionnaire.questions[1].question_type).to eq("long_answer")
            expect(questionnaire.questions[2].answer_options[1]["body"]["en"]).to eq(form_params["questions"]["2"]["answer_options"]["1"]["body"]["en"])

            expect(questionnaire.questions[2].question_type).to eq("single_option")
            expect(questionnaire.questions[2].max_choices).to be_nil

            expect(questionnaire.questions[3].question_type).to eq("multiple_option")
            expect(questionnaire.questions[2].answer_options[0].free_text).to eq(false)
            expect(questionnaire.questions[2].max_choices).to be_nil

            expect(questionnaire.questions[3].question_type).to eq("multiple_option")
            expect(questionnaire.questions[3].answer_options[0].free_text).to eq(true)
            expect(questionnaire.questions[3].max_choices).to eq(2)

            expect(questionnaire.questions[4].question_type).to eq("matrix_single")
            expect(questionnaire.questions[4].answer_options[0].free_text).to eq(true)
            expect(questionnaire.questions[4].matrix_rows[0].body["en"]).to eq(form_params["questions"]["4"]["matrix_rows"]["0"]["body"]["en"])

            expect(questionnaire.questions[5].question_type).to eq("matrix_multiple")
            expect(questionnaire.questions[5].answer_options[0].free_text).to eq(true)
            expect(questionnaire.questions[5].matrix_rows[0].body["en"]).to eq(form_params["questions"]["5"]["matrix_rows"]["0"]["body"]["en"])
          end
        end
      end
    end
  end
end
