# Future fine-tuning data (no trained model is included)

Start by evaluating the **base model + current UEHero data retrieval**. Training is not required for the first milestone.

If testing shows recurring problems with interview coaching style, gather consented, anonymized and reviewed examples in JSONL with e.g.:

{"messages":[{"role":"user","content":"Hỏi mình một câu phỏng vấn Business Analyst intern."},{"role":"assistant","content":"Khi yêu cầu từ khách hàng chưa rõ, bạn sẽ làm gì để làm rõ yêu cầu?"}]}

* At least separate evaluation examples must be kept out of training.
* Label events with **source dates** rather than teaching a model that a registration deadline is permanently true.
* Don't put actual student CVs, transcripts, or personal details in training data without explicit consent.
* Run local QLoRA/LoRA only once data quality and a measurable baseline are established. A 6GB GPU may require a small model, reduced sequence length and batch size.
* Do not claim that generic chat examples are evidence of improved performance. Compare blind evaluation prompts before/after fine-tuning.
