/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked for a survivor or si
 * @remarks Called every frame to update a client's m_nSequence netprop
 *
 * @param client   the client that is playing as a survivor or special infected
 * @param sequence  current selected sequence m_nSequence, option to override the return value with it
 *
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action:L4D2_OnSelectWSequence(client, &sequence);

public Extension:__ext_DCExt = 
{
	name = "DCExt",
	file = "DCExt.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
