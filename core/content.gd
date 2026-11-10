class_name Content
extends RefCounted
## All game data: emotions, body clues, coping techniques, scenarios, pets.
## Pure data + lookups, no engine nodes, so it can be unit tested.

const EMOTIONS := {
	"mad": {"label": "Mad", "color": Color("ef6f5e"),
		"brain": "Big mad feelings make the thinking brain go fuzzy. It is hard to make good choices until the body is calm."},
	"frustrated": {"label": "Frustrated", "color": Color("f59e42"),
		"brain": "Frustration makes the brain say \"I can't!\" and want to quit. A calm body helps the brain try again."},
	"worried": {"label": "Worried", "color": Color("a58be0"),
		"brain": "Worry makes the brain shout \"What if?!\" over and over, even when we are safe."},
	"sad": {"label": "Sad", "color": Color("6fa8dc"),
		"brain": "Sad feelings can make everything look gray for a while. Sad feelings come, and they also go."},
	"disappointed": {"label": "Disappointed", "color": Color("8fa3b8"),
		"brain": "Disappointment makes the brain forget the good things that can still happen."},
	"jealous": {"label": "Jealous", "color": Color("7dbb6a"),
		"brain": "Jealous feelings make the brain only see what we don't have."},
	"embarrassed": {"label": "Embarrassed", "color": Color("ee8fa8"),
		"brain": "Embarrassed feelings make the brain think everyone is staring. Really, everybody makes mistakes."},
	"calm": {"label": "Calm", "color": Color("8fd6c2"), "brain": ""},
	"happy": {"label": "Happy", "color": Color("ffd166"), "brain": ""},
}

## Emotions a scenario can be about (calm/happy are only used for display).
const BIG_FEELINGS := ["mad", "frustrated", "worried", "sad", "disappointed", "jealous", "embarrassed"]

## When the child has not recorded an animal sound for a feeling, a close one is used.
const SOUND_FALLBACK := {
	"mad": ["frustrated"], "frustrated": ["mad"], "jealous": ["mad", "frustrated"],
	"sad": ["disappointed"], "disappointed": ["sad"], "worried": ["embarrassed"],
	"embarrassed": ["worried", "sad"], "calm": ["happy"], "happy": ["calm"],
}

const BODY_CLUES := {
	"hot_face": "Hot face",
	"tight_paws": "Tight, squeezy paws",
	"fast_heart": "Fast, thumpy heart",
	"tummy": "Fluttery tummy",
	"wobbly": "Wobbly legs",
	"fast_breath": "Fast breathing",
	"loud": "Loud voice",
	"tears": "Teary eyes",
	"heavy": "Heavy, droopy body",
	"tight_jaw": "Tight teeth",
	"lump": "Lump in the throat",
	"red_cheeks": "Red, warm cheeks",
	"hunched": "Small, hunched body",
}

## Feeling thermometer labels, 1..5.
const SIZE_WORDS := ["", "Tiny", "Small", "Medium", "Big", "HUGE"]

## Coping techniques, in the order they are introduced.
## `for` lists the feelings each one is offered for.
const TECHNIQUE_ORDER := ["balloon", "count", "turtle", "squeeze", "glitter", "look", "thoughts", "stretch"]

const TECHNIQUES := {
	"balloon": {
		"name": "Balloon Breaths", "color": Color("8ed1f0"),
		"short": "Breathe in slow, breathe out slower.",
		"how": "Hold down to breathe in and fill the balloon. Let go to breathe out slowly.",
		"for": ["mad", "frustrated", "worried", "sad", "disappointed", "jealous", "embarrassed"],
		"science": "Slow belly breathing with a longer out-breath. Lowers heart rate and body arousal.",
	},
	"count": {
		"name": "Slow Count to 10", "color": Color("ffd166"),
		"short": "Count slowly before you do anything.",
		"how": "Tap each firefly when it lights up. No rushing!",
		"for": ["mad", "frustrated", "jealous", "disappointed"],
		"science": "A short delay between the feeling and the action. Gives the impulse time to pass.",
	},
	"turtle": {
		"name": "Turtle Shell", "color": Color("7bc47f"),
		"short": "Stop. Tuck in. Breathe. Think.",
		"how": "Stop, tuck into your shell, take 3 slow breaths, then think.",
		"for": ["mad", "frustrated", "jealous"],
		"science": "The Turtle Technique from the PATHS school program: stop, withdraw, breathe, think of a solution.",
	},
	"squeeze": {
		"name": "Squeeze and Melt", "color": Color("ff8c7a"),
		"short": "Squeeze tight, then melt like ice cream.",
		"how": "Hold down to squeeze your muscles tight. Let go and melt.",
		"for": ["mad", "frustrated", "worried", "embarrassed"],
		"science": "Progressive muscle relaxation: tensing then releasing muscle groups to let go of body tension.",
	},
	"glitter": {
		"name": "Glitter Jar Break", "color": Color("b9a6f0"),
		"short": "Take a break and watch the glitter settle.",
		"how": "Shake the jar, then watch quietly until all the glitter settles.",
		"for": ["mad", "frustrated", "worried", "sad", "disappointed", "jealous", "embarrassed"],
		"science": "A self-chosen calm-down break with a mindful focus, taken to cool off (not as a punishment).",
	},
	"look": {
		"name": "Look Around", "color": Color("f2a6c8"),
		"short": "Notice what you see, hear and feel right now.",
		"how": "Find things you can see, sounds you can hear, and feel your feet on the floor.",
		"for": ["worried", "sad", "embarrassed"],
		"science": "Sensory grounding (5-4-3-2-1 style): moving attention from worries to the present moment.",
	},
	"thoughts": {
		"name": "Helpful Thoughts", "color": Color("ffb86b"),
		"short": "Swap a stormy thought for a helpful one.",
		"how": "Shrink the stormy thought, then pick a thought that helps.",
		"for": ["mad", "frustrated", "worried", "sad", "disappointed", "jealous", "embarrassed"],
		"science": "Cognitive reappraisal and coping self-talk, core skills in CBT for children (for example Coping Cat).",
	},
	"stretch": {
		"name": "Slow Stretch", "color": Color("9ad0a0"),
		"short": "Reach up slow like a tall tree.",
		"how": "Follow the sun slowly with your finger. Slow is the trick!",
		"for": ["mad", "frustrated", "worried", "sad", "disappointed", "embarrassed"],
		"science": "Slow, gentle movement. Calming activity lowers anger; fast, hard exercise in the moment does not.",
	},
}

## Skill stages. Adults can set these by hand in the grown-ups menu.
const STAGE_LOCKED := 0    # not introduced yet
const STAGE_LEARNING := 1  # guided, step by step
const STAGE_PRACTICE := 2  # child picks it and leads the pet
const STAGE_LEARNED := 3   # pet often asks for it; child co-practices
const STAGE_NAMES := ["Not yet", "Learning", "Practicing", "Learned"]

const SPECIES := {
	"dog": "Biscuit", "cat": "Mittens", "bunny": "Clover", "fox": "Maple",
	"panda": "Bao", "penguin": "Pebble", "koala": "Koko", "pig": "Truffle",
	"chick": "Peep", "elephant": "Ellie", "lion": "Leo", "tiger": "Tango",
	"monkey": "Momo", "giraffe": "Gigi", "deer": "Fawna", "cow": "Daisy",
	"hog": "Bristle", "beaver": "Chip", "crab": "Snips", "parrot": "Kiwi",
	"polar": "Snowy", "bee": "Buzz", "caterpillar": "Inch", "fish": "Bubbles",
}
const STARTER_SPECIES := ["dog", "cat", "bunny"]
const ARRIVAL_ORDER := ["fox", "panda", "penguin", "koala", "pig", "chick", "elephant",
	"lion", "monkey", "tiger", "giraffe", "deer", "cow", "beaver", "parrot", "polar",
	"hog", "crab", "bee", "caterpillar", "fish"]

## Special colours. Every animal also comes in each of these, so the roster is
## 24 animals x 4 looks. `hue` turns the colours around the colour wheel and
## `tint` colours the white and grey parts ("" is the everyday look).
const LOOK_ORDER := ["rose", "sky", "mint"]
const LOOKS := {
	"rose": {"hue": 0.88, "tint": Color("ffb8d2")},
	"sky": {"hue": 0.55, "tint": Color("b4d6ff")},
	"mint": {"hue": 0.3, "tint": Color("b6f0c2")},
}
## Names for special-colour pets (the child can type a different one).
const EXTRA_NAMES := ["Pip", "Sunny", "Waffles", "Noodle", "Pickle", "Mochi", "Peanut", "Bean",
	"Pumpkin", "Sprout", "Coco", "Honey", "Jellybean", "Dot", "Fig", "Twig", "Olive", "Poppy",
	"Tater", "Ziggy", "Juniper", "Marble", "Nugget", "Pepper", "Plum", "Rolo", "Skittle",
	"Taffy", "Toffee", "Whiskers", "Zuzu", "Blossom", "Button", "Cricket", "Dumpling",
	"Flapjack", "Gumdrop", "Hopscotch", "Jojo", "Kazoo", "Lolly", "Muffin", "Nibbles",
	"Oreo", "Pancake", "Quill", "Ruffles", "Sprinkle", "Tumble", "Wiggles", "Yoyo", "Acorn",
	"Bubba", "Cupcake", "Doodle", "Echo", "Fudge", "Giggles", "Huckle", "Iggy", "Jazz",
	"Kiki", "Lemon", "Mango", "Nori", "Otto", "Pogo", "Rosie", "Scout", "Tinker", "Velvet",
	"Winnie"]

## Some pets like everything to be just right. They get the "perfect" stories:
## wobbly lines, wrong answers, being scared to try in case it goes wrong.
const PERFECTIONISTS := ["cat", "fox", "penguin", "beaver", "bee", "giraffe", "parrot", "deer"]
const TRAIT_LABELS := {"perfect": "Likes things just right"}

const FOODS := ["apple", "carrot", "fish", "banana", "cookie", "watermelon", "strawberry",
	"cupcake", "honey", "corn", "cheese", "broccoli", "pear", "grapes"]

## Things to notice in the Look Around exercise: icon + what the pet says.
const LOOK_ITEMS := [
	["apple", "a red apple"], ["banana", "a yellow banana"], ["carrot", "an orange carrot"],
	["broccoli", "green broccoli"], ["grapes", "purple grapes"], ["lemon", "a yellow lemon"],
	["strawberry", "a red strawberry"], ["pear", "a green pear"], ["pumpkin", "an orange pumpkin"],
	["eggplant", "a purple eggplant"], ["tomato", "a red tomato"], ["orange", "a round orange"],
]

## Scenarios. Text placeholders: {pet} the pet with the feeling, {friend} another pet.
## also: other feeling names that are accepted as a right answer.
## impulse: the unsafe urge, and `then`: what would happen (shown as "let's imagine").
const SCENARIOS := [
	{"id": "tower_fell", "emotion": "frustrated", "also": ["mad"], "level": 4,
		"story": "{pet} built a tall block tower. Then... CRASH! It all fell down.",
		"hot": "I can NEVER do it! I quit forever!",
		"impulse": "Kick the blocks everywhere", "then": "Blocks fly everywhere and one bonks {friend}. Now {pet} feels even worse.",
		"clues": ["hot_face", "tight_paws", "tight_jaw"],
		"helpful": ["Towers fall sometimes. I can build it again.", "I'm still learning. Every try makes me better."],
		"good": ["Try again with a wider bottom", "Ask a friend to help build"],
		"bad": "Quit and never build again", "bad_why": "Then {pet} would miss out on something fun.",
		"ending": "{pet} built it again. When it wobbled, {pet} took a slow breath and kept going!"},
	{"id": "toy_taken", "emotion": "mad", "also": [], "level": 4,
		"story": "{friend} grabbed {pet}'s favorite ball without asking.",
		"hot": "{friend} is the WORST! I will never share again!",
		"impulse": "Push {friend} and grab it back", "then": "{friend} gets hurt and cries. Now two pets feel awful.",
		"clues": ["hot_face", "tight_paws", "loud", "fast_heart"],
		"helpful": ["{friend} forgot to ask. I can say how I feel.", "I can get my ball back with my words."],
		"good": ["Say: I feel mad when you take my ball. Please ask first.", "Ask a helper for help"],
		"bad": "Take {friend}'s toy to get even", "bad_why": "Then both pets would be mad, and the problem would get bigger.",
		"ending": "{friend} said sorry. Now they are taking turns with the ball."},
	{"id": "lost_race", "emotion": "mad", "also": ["disappointed", "frustrated"], "level": 3,
		"story": "{pet} and {friend} had a race. {friend} won.",
		"hot": "It's not fair! {friend} cheated!",
		"impulse": "Yell \"Cheater!\" and stomp away", "then": "{friend} feels hurt and does not want to play any more.",
		"clues": ["hot_face", "tight_jaw", "fast_heart"],
		"helpful": ["Losing feels bad, but it was still a fun race.", "Sometimes I win, sometimes my friend wins."],
		"good": ["Say: Good race! Want to go again?", "Take a breath and pick a new game"],
		"bad": "Say you never want to play with {friend} again", "bad_why": "Then {pet} would lose a friend, not just a race.",
		"ending": "{pet} said \"Good race!\" and they played again. It was fun even without winning."},
	{"id": "thunder", "emotion": "worried", "also": [], "level": 4,
		"story": "Dark clouds rolled in. BOOM! Thunder shook the sky.",
		"hot": "What if the storm never stops? What if it gets me?",
		"impulse": "Hide under the bed all day and all night", "then": "Hiding alone makes the worry grow bigger and bigger.",
		"clues": ["fast_heart", "tummy", "wobbly", "fast_breath"],
		"helpful": ["Thunder is loud, but I am safe inside.", "Storms always end."],
		"good": ["Sit close to a friend and listen to the rain", "Ask a helper for a cuddle"],
		"bad": "Run outside into the storm", "bad_why": "That would not be safe.",
		"ending": "{pet} snuggled up and listened to the rain. The storm passed, just like always."},
	{"id": "new_arrival", "emotion": "worried", "also": [], "level": 4, "tag": "arrival",
		"story": "{pet} just arrived at the sanctuary. Everything here is brand new!",
		"hot": "What if nobody likes me?",
		"impulse": "Hide in the travel box and never come out", "then": "{pet} would stay lonely, and the worry would never get a chance to shrink.",
		"clues": ["fast_heart", "tummy", "wobbly"],
		"helpful": ["New places feel scary at first. Then they feel like home.", "I can meet just one friend to start."],
		"good": ["Say hi to one friendly pet", "Take a slow walk around together"],
		"bad": "Growl so everyone stays away", "bad_why": "Then nobody would get to know how nice {pet} is.",
		"ending": "{pet} said a tiny \"hi\" to {friend}. {friend} said hi back! This place might be OK."},
	{"id": "checkup", "emotion": "worried", "also": [], "level": 3,
		"story": "Today is check-up day with the animal doctor.",
		"hot": "What if it hurts? I can't do it!",
		"impulse": "Run away and hide in the bushes", "then": "The check-up still has to happen, and now {pet} is worried AND tired.",
		"clues": ["tummy", "fast_heart", "fast_breath"],
		"helpful": ["The doctor helps me stay healthy. It will be quick.", "I can be brave AND a little scared."],
		"good": ["Bring a comfy toy along", "Ask what will happen first"],
		"bad": "Pretend to be asleep all day", "bad_why": "The worry would just wait until tomorrow.",
		"ending": "The check-up was quick. {pet} even got a sticker for being brave!"},
	{"id": "left_out", "emotion": "sad", "also": [], "level": 3,
		"story": "{friend} and the others were playing. Nobody asked {pet} to join.",
		"hot": "Nobody likes me.",
		"impulse": "Sit alone and tell everyone to go away", "then": "{pet} would feel even more alone.",
		"clues": ["tears", "heavy", "lump"],
		"helpful": ["Maybe they did not see me. I can ask to join.", "I have friends who care about me."],
		"good": ["Ask: Can I play too?", "Invite someone to a new game"],
		"bad": "Knock over their game", "bad_why": "Then they would be upset, and {pet} still would not get to play.",
		"ending": "{pet} asked \"Can I play too?\" and {friend} said \"Yes! We need one more!\""},
	{"id": "rain_picnic", "emotion": "disappointed", "also": ["sad"], "level": 3,
		"story": "Today was picnic day! But it is raining, so the picnic is off.",
		"hot": "Today is RUINED! Nothing good ever happens!",
		"impulse": "Throw the picnic basket", "then": "The snacks get squished, and now there is a mess to clean up.",
		"clues": ["heavy", "tears", "lump"],
		"helpful": ["I'm disappointed. We can have the picnic another day.", "We could have an inside picnic!"],
		"good": ["Make an indoor picnic", "Pick a new picnic day"],
		"bad": "Say no to everything all day", "bad_why": "Then the whole day would feel yucky, not just the picnic.",
		"ending": "{pet} made a blanket picnic inside. Rain picnics are cozy!"},
	{"id": "new_pet_cuddles", "emotion": "jealous", "also": [], "level": 3,
		"story": "Everyone is cuddling {friend}. {pet} wants cuddles too.",
		"hot": "They like {friend} more than me!",
		"impulse": "Bump {friend} out of the way", "then": "{friend} gets hurt, and nobody feels like cuddling.",
		"clues": ["hot_face", "tummy", "tight_paws"],
		"helpful": ["There are enough cuddles for everyone.", "I can ask for a cuddle too."],
		"good": ["Ask: Can I have a cuddle too?", "Join in and cuddle together"],
		"bad": "Be grumpy at {friend} all day", "bad_why": "{friend} did nothing wrong, and {pet} would still want a cuddle.",
		"ending": "{pet} asked for a cuddle and got a BIG one. There was plenty to go around."},
	{"id": "puzzle_hard", "emotion": "frustrated", "also": ["mad"], "level": 3,
		"story": "{pet} can't fit the last puzzle piece. It just won't go in!",
		"hot": "This is too hard! I am no good at puzzles!",
		"impulse": "Smash the puzzle", "then": "All the pieces scatter, and now the puzzle is even harder.",
		"clues": ["tight_paws", "tight_jaw", "hot_face"],
		"helpful": ["Hard things take time. I can take a break and come back.", "I can't do it YET."],
		"good": ["Turn the piece and try a new way", "Take a break, then try again"],
		"bad": "Throw the piece away", "bad_why": "Then the puzzle could never be finished.",
		"ending": "After a break, {pet} turned the piece around. Click! It fit."},
	{"id": "waiting_turn", "emotion": "frustrated", "also": ["mad"], "level": 3,
		"story": "{pet} has been waiting SO long for a turn on the swing.",
		"hot": "I will NEVER get a turn!",
		"impulse": "Shove to the front of the line", "then": "Someone gets knocked over, and {pet} has to wait even longer.",
		"clues": ["tight_paws", "hot_face", "fast_breath"],
		"helpful": ["Waiting is hard, but my turn is coming.", "I can do something fun while I wait."],
		"good": ["Ask: How many more minutes?", "Count the swings while waiting"],
		"bad": "Yell at {friend} to get off", "bad_why": "Yelling makes everyone upset, and the wait feels longer.",
		"ending": "{pet} counted ten swings, and then it was {pet}'s turn. Wheee!"},
	{"id": "broken_toy", "emotion": "sad", "also": ["mad", "disappointed"], "level": 3,
		"story": "{pet}'s favorite squeaky toy broke. No more squeak.",
		"hot": "It's gone forever. I'll never be happy again.",
		"impulse": "Break another toy too", "then": "Now two toys are broken, and {pet} feels twice as sad.",
		"clues": ["tears", "lump", "heavy"],
		"helpful": ["I feel sad because I loved that toy. That's OK.", "Maybe a helper can fix it."],
		"good": ["Ask a helper to help fix it", "Tell a friend about the sad feeling"],
		"bad": "Hide the toy and pretend nothing happened", "bad_why": "The sad feeling would stay stuck inside.",
		"ending": "A little tape and a new squeaker later, the toy squeaks again! Squeak!"},
	{"id": "dark_bedtime", "emotion": "worried", "also": [], "level": 3,
		"story": "It is bedtime, and the sleeping den looks very dark.",
		"hot": "What if there is a monster in there?",
		"impulse": "Stay awake all night long", "then": "{pet} would be SO tired tomorrow, and still worried.",
		"clues": ["fast_heart", "fast_breath", "tummy"],
		"helpful": ["My den is safe. My friends are sleeping close by.", "The dark is the same room, just resting."],
		"good": ["Ask for a night light", "Snuggle a comfy blanket"],
		"bad": "Keep everyone else awake too", "bad_why": "Then everybody would be tired and grumpy.",
		"ending": "With a little night light, the den looked cozy. {pet} fell fast asleep."},
	{"id": "spill", "emotion": "frustrated", "also": ["sad", "mad"], "level": 3,
		"story": "{pet} spilled the whole water bowl. SPLASH!",
		"hot": "I'm so clumsy! I mess up everything!",
		"impulse": "Hide and say {friend} did it", "then": "{friend} gets blamed and feels hurt. {pet}'s tummy feels yucky about it.",
		"clues": ["hot_face", "tight_jaw", "lump"],
		"helpful": ["Everybody spills sometimes. I can clean it up.", "Mistakes help me learn."],
		"good": ["Get a towel and wipe it up", "Say: Oops! Can you help me?"],
		"bad": "Kick the bowl", "bad_why": "That would make a bigger mess.",
		"ending": "{pet} wiped it up in no time. Oops fixed!"},
	{"id": "no_treat", "emotion": "mad", "also": ["disappointed"], "level": 4,
		"story": "{pet} wants another treat. But the answer is: no more treats today.",
		"hot": "It's NOT FAIR! I want it NOW!",
		"impulse": "Scream and stomp until someone gives in", "then": "Screaming makes {pet}'s throat sore and the mad feeling bigger. And still no treat.",
		"clues": ["hot_face", "loud", "tight_paws", "fast_heart"],
		"helpful": ["I don't like \"no\", but I can handle it.", "There will be a treat tomorrow."],
		"good": ["Say: I'm mad... but OK. Maybe tomorrow?", "Find something else fun to do"],
		"bad": "Sneak a treat anyway", "bad_why": "Sneaking breaks trust, and trust is hard to fix.",
		"ending": "{pet} said \"OK, maybe tomorrow\" and went to play. Handling a \"no\" is a superpower!"},
	{"id": "loud_party", "emotion": "worried", "also": ["frustrated"], "level": 3,
		"story": "The sanctuary party is SO loud and busy. Too much noise!",
		"hot": "Too much! Too much! I can't stand it!",
		"impulse": "Scream at everyone to be quiet", "then": "Now it is even louder, and everyone is staring.",
		"clues": ["fast_heart", "fast_breath", "tight_paws"],
		"helpful": ["I can take a quiet break and come back.", "It's OK to need some quiet."],
		"good": ["Take a break in the calm corner", "Tell a helper: It's too loud for me"],
		"bad": "Knock over the music player", "bad_why": "That would break it and upset the others.",
		"ending": "After a quiet break, {pet} came back and danced near the edge. Just right!"},
	{"id": "friend_adopted", "emotion": "sad", "also": [], "level": 3,
		"story": "{pet}'s buddy from the old home moved far away today.",
		"hot": "I will be lonely forever.",
		"impulse": "Refuse to play with anyone ever again", "then": "{pet} would feel lonelier and lonelier.",
		"clues": ["tears", "heavy", "lump"],
		"helpful": ["I can miss my buddy AND make new friends.", "I can remember our fun times."],
		"good": ["Draw a picture for the buddy", "Play with {friend} today"],
		"bad": "Stay in bed all day", "bad_why": "A little sad time is OK, but all day makes the sad feeling stick.",
		"ending": "{pet} drew a picture to send. Then {friend} came over to play."},
	{"id": "time_to_stop", "emotion": "mad", "also": ["disappointed", "frustrated"], "level": 3,
		"story": "{pet} was having SO much fun. Now it is time to stop and come inside.",
		"hot": "No! I am NOT stopping!",
		"impulse": "Run away and pretend not to hear", "then": "Now the helpers are worried, and tomorrow's playtime gets shorter.",
		"clues": ["hot_face", "tight_paws", "loud"],
		"helpful": ["Stopping is hard. I can play again tomorrow.", "One last jump, then I go in."],
		"good": ["Ask: Can I have one more minute?", "Pick what to play first tomorrow"],
		"bad": "Flop down and refuse to move", "bad_why": "Then everyone has to wait, and the mad feeling gets bigger.",
		"ending": "{pet} did one last BIG jump and came inside. Tomorrow there will be more play!"},
]

## Stories for pets that want everything to be perfect (see PERFECTIONISTS).
## What they practice: mistakes are how we learn, nobody is watching as closely
## as it feels, and "good enough" really is good.
const PERFECT_SCENARIOS := [
	{"id": "wobbly_line", "trait": "perfect", "emotion": "frustrated", "also": ["mad", "disappointed"], "level": 4,
		"story": "{pet} was drawing a picture for {friend}. Then one line went all wobbly.",
		"hot": "It's ruined! It has to be perfect!",
		"impulse": "Rip the picture into little bits", "then": "All the good parts get ripped up too. Now there is no picture at all.",
		"clues": ["tight_paws", "hot_face", "tight_jaw"],
		"helpful": ["It does not have to be perfect to be good.", "A wobbly line can turn into something new."],
		"good": ["Turn the wobbly line into a flower", "Give it to {friend} just as it is"],
		"bad": "Never draw again", "bad_why": "Then {pet} would miss out on all the fun of drawing.",
		"ending": "{pet} turned the wobbly line into a curly vine. {friend} said it was the best part!"},
	{"id": "wrong_answer", "trait": "perfect", "emotion": "embarrassed", "also": [], "level": 4,
		"story": "At pet school, {pet} said the wrong answer out loud. Everybody heard.",
		"hot": "Everyone thinks I am silly! I am never answering again!",
		"impulse": "Hide under the table and not come out", "then": "Hiding makes the embarrassed feeling grow. And {pet} misses the fun part of class.",
		"clues": ["red_cheeks", "hunched", "tummy"],
		"helpful": ["Everybody gets answers wrong. That is how brains grow.", "A mistake means I am learning something new."],
		"good": ["Say: Oops! Let me try again.", "Ask the teacher to explain it"],
		"bad": "Never put a paw up again", "bad_why": "Then {pet} would not get to learn new things.",
		"ending": "{pet} said \"Oops!\" and tried again. {friend} whispered: \"I got it wrong last week too.\""},
	{"id": "start_over", "trait": "perfect", "emotion": "frustrated", "also": ["mad"], "level": 3,
		"story": "{pet} keeps knocking down the sandcastle to start over. It is never just right.",
		"hot": "It has to be PERFECT or it is no good!",
		"impulse": "Stomp the castle flat again", "then": "Now playtime is nearly over, and there is still no castle.",
		"clues": ["tight_jaw", "tight_paws", "fast_breath"],
		"helpful": ["Good enough is good. I can stop fixing and start playing.", "Nothing is perfect, and that is OK."],
		"good": ["Leave the bumpy tower and add a flag", "Ask {friend} what they like about it"],
		"bad": "Keep starting over until bedtime", "bad_why": "Then there would be no time left to play in it.",
		"ending": "{pet} left the bumpy tower just as it was. {friend} moved in a toy crab. Perfect for playing!"},
	{"id": "scared_to_try", "trait": "perfect", "emotion": "worried", "also": ["embarrassed"], "level": 3,
		"story": "{pet} wants to try the new balance log. But what if {pet} falls off?",
		"hot": "If I can't do it right the first time, I won't do it at all.",
		"impulse": "Say \"It looks boring\" and walk away", "then": "{pet} watches the others have fun, and the worry stays just as big.",
		"clues": ["tummy", "fast_heart", "wobbly"],
		"helpful": ["Nobody is good at new things right away.", "Falling off is part of learning. I can get back on."],
		"good": ["Try just one tiny step", "Ask {friend} to hold a paw"],
		"bad": "Wait until nobody is ever looking", "bad_why": "Then {pet} might never get a turn at all.",
		"ending": "{pet} wobbled, fell off, and got back on. After five tries, {pet} made it across!"},
	{"id": "tripped_show", "trait": "perfect", "emotion": "embarrassed", "also": ["sad"], "level": 3,
		"story": "{pet} tripped in the middle of the dance show. Bonk!",
		"hot": "Everybody saw! I can never dance again!",
		"impulse": "Run off the stage and hide", "then": "The show goes on without {pet}, and the embarrassed feeling gets bigger.",
		"clues": ["red_cheeks", "hunched", "fast_heart"],
		"helpful": ["Everybody trips sometimes. It is no big deal.", "My friends still like me when I make a mistake."],
		"good": ["Hop up and keep dancing", "Take a bow and smile"],
		"bad": "Blame {friend} for being in the way", "bad_why": "{friend} did nothing wrong, and blaming would hurt.",
		"ending": "{pet} hopped up and did a silly bow. Everybody clapped!"},
	{"id": "one_wrong", "trait": "perfect", "emotion": "disappointed", "also": ["sad", "frustrated"], "level": 3,
		"story": "{pet} got nine stars on the puzzle sheet. One puzzle was wrong.",
		"hot": "I got one wrong. I am no good at this!",
		"impulse": "Crumple up the whole sheet", "then": "The nine stars get crumpled too. Now {pet} feels even worse.",
		"clues": ["heavy", "lump", "tears"],
		"helpful": ["Nine stars is great. One miss shows me what to practice.", "I tried my best, and that is what matters."],
		"good": ["Look at the tricky one and try it again", "Show {friend} the nine stars"],
		"bad": "Hide the sheet so nobody sees", "bad_why": "Then nobody could help with the tricky one.",
		"ending": "{pet} tried the tricky puzzle again and worked it out. Mistakes show us what to learn next!"},
]

## Used for the "that was frustrating for us both" moments inside activities.
const ACTIVITY_FRUSTRATION := {
	"id": "activity", "emotion": "frustrated", "also": ["mad"], "level": 3,
	"story": "",
	"hot": "This is too hard! I want to quit!",
	"impulse": "Mess it all up and quit", "then": "Then the fun would be over, and the frustrated feeling would still be there.",
	"clues": ["tight_paws", "hot_face", "tight_jaw"],
	"helpful": ["That was frustrating. I can try again.", "It's just a game. I can keep cool."],
	"good": ["Try again", "Try again a little slower"],
	"bad": "Quit and say the game is dumb", "bad_why": "The game is still fun. The feeling is just big right now.",
	"ending": "{pet} is ready to try again. Calm bodies play better!",
}


static func scenario_by_id(id: String) -> Dictionary:
	if id == "activity":
		return ACTIVITY_FRUSTRATION
	for s in all_scenarios():
		if s.id == id:
			return s
	return {}


static func all_scenarios() -> Array:
	return SCENARIOS + PERFECT_SCENARIOS


static func trait_of(species: String) -> String:
	return "perfect" if PERFECTIONISTS.has(species) else ""


## How many different pets there are to collect (every animal in every look).
static func roster_size() -> int:
	return SPECIES.size() * (LOOK_ORDER.size() + 1)


## Lines the child can record straight away: the pets' own words (stormy and
## helpful thoughts). Everything else the game says turns up in the recording
## booth after it has been heard once.
static func voice_script() -> Array:
	var out := ["Ahhh. I feel calm now.", "Ahhh. My feeling got smaller!"]
	for s in all_scenarios() + [ACTIVITY_FRUSTRATION]:
		for line in s.helpful + [s.hot]:
			if not line.contains("{"):
				out.append(line)
	return out


static func fill(text: String, pet: String, friend: String) -> String:
	return text.replace("{pet}", pet).replace("{friend}", friend)


## Body clues that do NOT belong to this scenario, used as gentle distractors.
static func wrong_clues(scenario: Dictionary) -> Array:
	var out := []
	for c in BODY_CLUES.keys():
		if not scenario.clues.has(c):
			out.append(c)
	return out
