--!strict
--[[ GENERERAD av tools/exportera-spel.js ur src/spel/skotsel.js.
     Ändra inte här — ändra i källan och kör om exporten. ]]

return {
	rykt = {
		zoner = {
			{
				x = 0.44,
				y = 0.31,
				typ = "kropp",
			},
			{
				x = 0.45,
				y = 0.46,
				typ = "kropp",
			},
			{
				x = 0.55,
				y = 0.39,
				typ = "kropp",
			},
			{
				x = 0.55,
				y = 0.54,
				typ = "kropp",
			},
			{
				x = 0.66,
				y = 0.52,
				typ = "kropp",
			},
			{
				x = 0.73,
				y = 0.44,
				typ = "kropp",
			},
			{
				x = 0.43,
				y = 0.57,
				typ = "kropp",
			},
			{
				x = 0.7,
				y = 0.59,
				typ = "kropp",
			},
			{
				x = 0.285,
				y = 0.3,
				typ = "huvud",
			},
			{
				x = 0.45,
				y = 0.73,
				typ = "ben",
			},
			{
				x = 0.71,
				y = 0.73,
				typ = "ben",
			},
		},
		redskap = {
			{
				id = "skrapa",
				namn = "Gummiskrapa",
				kort = "cirklar",
				farg = Color3.fromRGB(127, 180, 137),
				text = "Cirklar på musklerna. Aldrig över ben eller huvud.",
			},
			{
				id = "hard",
				namn = "Kardborste",
				kort = "korta drag",
				farg = Color3.fromRGB(214, 174, 60),
				text = "Korta drag med hårets riktning — bakåt.",
			},
			{
				id = "mjuk",
				namn = "Mjuk borste",
				kort = "långa drag",
				farg = Color3.fromRGB(191, 212, 222),
				text = "Långa drag, hela kroppen och benen.",
			},
		},
		krav = {
			kropp = {
				"skrapa",
				"hard",
				"mjuk",
			},
			ben = {
				"hard",
				"mjuk",
			},
			huvud = {
				"mjuk",
			},
		},
	},
	sadelfaser = {
		{
			t = "Lägg underlägget högt på manken och skjut det bakåt i hårets riktning.",
		},
		{
			t = "Lägg sadeln lite för långt fram och skjut den bakåt på plats, bakom bogbladet.",
		},
		{
			t = "Klicka i sadelbommen och lyft upp underlägget — manken ska vara fri.",
		},
		{
			t = "Gjorda i tre tag, med en paus emellan. Aldrig allt på en gång.",
		},
	},
	visitation = {
		punkter = {
			{
				id = "ogon",
				x = 0.25,
				y = 0.283,
				namn = "Ögon och nos",
				ok = "Klara ögon, torr nos. %N ser dig i ögonen — hon är pigg idag.",
			},
			{
				id = "mun",
				x = 0.267,
				y = 0.33,
				namn = "Mungiporna",
				ok = "Mjuka och hela. Bettet har inte skavt sedan sist.",
			},
			{
				id = "sadel",
				x = 0.56,
				y = 0.335,
				namn = "Sadelläget",
				ok = "Slät och sval rygg. %N står still när du trycker — inget ömmar.",
			},
			{
				id = "gjord",
				x = 0.5,
				y = 0.56,
				namn = "Gjordläget",
				ok = "Ingen svullnad bakom bogen. Huden är len där gjorden ska gå.",
			},
			{
				id = "ben",
				x = 0.455,
				y = 0.72,
				namn = "Benen",
				ok = "Svala och tunna hela vägen ner. %N lyfter foten innan du hinner be om det.",
			},
		},
		fynd = {
			ogon = "Nosen rinner och ögonen är lite matta.",
			mun = "En liten sårskorpa i vänstra mungipan.",
			sadel = "En varm, öm fläck mitt där sadeln ska ligga.",
			gjord = "Huden är röd och skavd efter gjorden.",
			ben = "Höger framben är varmare än det vänstra.",
		},
		svar = {
			{
				t = "Säg till ridläraren",
				ratt = true,
			},
			{
				t = "Det går nog bra idag",
				ratt = false,
			},
			{
				t = "Lös det själv och sadla",
				ratt = false,
			},
		},
	},
	faser = {
		{
			id = "halsa",
			namn = "Hälsa lugnt",
			krav = false,
			sitt = false,
			text = "Gå fram från sidan där hon ser dig och säg till innan du rör henne. Aldrig rakt bakifrån.",
		},
		{
			id = "visitera",
			namn = "Visitera",
			krav = true,
			sitt = false,
			text = "Ögon, mungipor, sadelläge, gjordläge och ben. Hittar du något: säg till ridläraren.",
		},
		{
			id = "rykta",
			namn = "Rykta",
			krav = true,
			sitt = false,
			text = "Skrapa, kardborste, mjuk borste. Huvudet bara med den mjuka.",
		},
		{
			id = "iordning",
			namn = "Gör i ordning",
			krav = true,
			sitt = false,
			text = "Kratsa alla fyra hovarna, lägg på underlägg och sadel, gjorda i tre tag.",
		},
		{
			id = "leda",
			namn = "Led till ridhuset",
			krav = true,
			sitt = false,
			text = "Led från vänster sida, vid bogen, med tyglarna över halsen. Hon går bredvid dig — inte efter, inte före.",
		},
		{
			id = "sittupp",
			namn = "Sitt upp",
			krav = false,
			sitt = true,
			text = "Först nu. Kontrollera gjorden en sista gång och sitt upp från vänster.",
		},
	},
	halsning = {
		{
			t = "Framifrån, och säg hennes namn",
			ratt = true,
			svar = "Hon lyfter huvudet och ser på dig. Nu vet hon att du är här.",
		},
		{
			t = "Från sidan vid bogen, med handen på halsen",
			ratt = true,
			svar = "Bra. Hon känner handen innan hon ser dig — och du står där hon kan se dig.",
		},
		{
			t = "Rakt bakifrån, tyst",
			ratt = false,
			svar = "Hon rycker till och slår upp huvudet. Bakifrån ser hon dig inte, och en häst som blir överrumplad sparkar först och tittar sedan.",
		},
	},
	hovar = {
		{
			id = "vf",
			namn = "Vänster fram",
			text = "Stå vänd bakåt, stryk ner längs benet och be om foten. Kratsa från trakten mot tån.",
		},
		{
			id = "vb",
			namn = "Vänster bak",
			text = "Håll handen på hennes höft hela vägen ner så hon vet var du är.",
		},
		{
			id = "hb",
			namn = "Höger bak",
			text = "Gå runt framför henne, aldrig tätt bakom. Samma grepp på andra sidan.",
		},
		{
			id = "hf",
			namn = "Höger fram",
			text = "Sista hoven. Titta efter sten i strålfårorna innan du släpper ner foten.",
		},
	},
	eftervard = {
		{
			id = "gjord",
			namn = "Lossa gjorden",
			text = "Lossa några hål direkt. Sadeln ligger kvar en stund till — ryggen ska få komma tillbaka långsamt.",
		},
		{
			id = "sadel",
			namn = "Ta av sadeln",
			text = "Sadel och underlägg av. Lägg handen på ryggen: den ska vara jämnt varm, utan ömma fläckar.",
		},
		{
			id = "trans",
			namn = "Ta av tränset",
			text = "Grimma på först, sedan tränset av. Hon ska aldrig stå lös i gången.",
		},
		{
			id = "ben",
			namn = "Känn igenom benen",
			text = "Nu, medan de är varma. En värme eller svullnad som inte fanns i morse ska ridläraren få veta om.",
		},
		{
			id = "vatten",
			namn = "Vatten och hö",
			text = "När andningen gått ner. Hö på golvet och rent vatten — och ett tack innan du går.",
		},
	},
}
