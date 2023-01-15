#!/bin/ksh
prompt="`cat`"

urlescape() {
	echo "$@" | sed 's/"/\\"/g' | sed 's/\n/,/g;s/,$/\n/'
}

#model=text-davinci-002
model=text-babbage-001
dialog() {
	cat <<!
{
	"model": "$model",
	"prompt": "`urlescape $prompt`",
	"temperature": 0.7,
	"max_tokens": 256,
	"top_p": 1,
	"frequency_penalty": 0,
	"presence_penalty": 0
}
!
}

DIALOG="`dialog`"

curl -s https://api.openai.com/v1/completions -H "Content-Type: application/json"   -H "Authorization: Bearer $OPENAI_API_KEY" -d "$DIALOG" > /tmp/gpt-response
cat /tmp/gpt-response 1>&2
cat /tmp/gpt-response | jq -r ".choices[0].text"
