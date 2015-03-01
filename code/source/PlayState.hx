package;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.FlxG;
import deengames.combocardgame.Deck;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();

		trace("Device: " + FlxG.width + "x" + FlxG.height);
		trace("Game: " + Main.virtualWidth + "x" + Main.virtualHeight);

		this.addAndShow('assets/images/background.png');
		var yourDeck = new Deck(7);

		// Five of yours
		for(n in 0...5) {
			// TODO: cards are not just strings!
			var cardName = yourDeck.dispenseCard();
			var card = this.makeCard(cardName);
			card.x = (n * card.width) + ((n+1) * 16);
			card.y = Main.virtualHeight - card.height -  16;
		}
	}

	private function makeCard(cardName:String) : FlxSpriteGroup
	{
		var base = addAndShow('assets/images/cards/card-base.png');
		var inhabitant = addAndShow("assets/images/cards/" + cardName + ".png");
		var border = addAndShow('assets/images/cards/card-border.png');
		// TODO: text
		var attackText = addText("A", 8, base.height - 28);
		var defenseText = addText("D", base.width - 24, base.height - 28);

		var group = new FlxSpriteGroup(0, 0);
		group.add(base);
		group.add(inhabitant);
		group.add(border);
		group.add(attackText);
		group.add(defenseText);
		//group.add(myText);
		return group;
	}

	private function addAndShow(string:String) : FlxSprite
	{
		var s:FlxSprite = new FlxSprite();
		s.loadGraphic(string);
		add(s);
		return s;
	}

	private function addText(string:String, x:Float, y:Float) : FlxText
	{
		var text = new FlxText(x, y, 0, string);
		text.size = 20;
		//text.setFormat("assets/font.ttf", 20, FlxColor.WHITE, "center");
		text.setBorderStyle(FlxText.BORDER_OUTLINE, FlxColor.BLACK, 1);
		add(text);
		return(text);
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		super.update();
	}
}
