import React, { useEffect, useState } from "react";
import DeleteConfirm from "../confirmpage/deleteconfirm";
import { formatNumberToCurrency } from "../../utils/formatNumbersToCurrency";
import { nuicallback } from "../../utils/nuicallback";
import { players } from "./data/players";
import { useDispatch, useSelector } from "react-redux";
import { icons } from "./data/icons";
import righticon from "../../assets/arrow-right.png";
import lefticon from "../../assets/arrow-left.png";
import settingsicon from "../../assets/setting.png";
import playicon from "../../assets/arrow.png";
import { updatescreen } from "../../store/screen/screen";
import { useConfig } from "../../providers/configprovider";
import profilepicture from "../../assets/profile.png";
import profilefemale from "../../assets/profile-female.png";

import createicon from "../../assets/create.png"
const CharDetails = () => {
  const [playersStore, SetPlayersStore] = useState(players);
  const [counter, setCounter] = useState(0);

  const { config } = useConfig();
  const dispatch = useDispatch();

  const scene = useSelector((state) => state.screen);

  useEffect(() => {
    nuicallback("GetCharacters").then((response) => {
      SetPlayersStore(response);
    });
  }, [scene]);

  const handleplay = () => {
    dispatch(updatescreen(""));
    nuicallback("playcharacter", playersStore[counter].id);
  };

  const handlecharacterswitch = (counter) => {
    setCounter(counter);

    let data = {
      emptyslot: playersStore[counter].emptyslot,
      counter: counter,
    };

    nuicallback("PreviewCharacter", data);
  };

  const handleQ = () => {
    if (counter !== 0) {
      nuicallback("click", false);
      handlecharacterswitch(counter - 1);
    }
  };
  const handleE = () => {
    if (counter < playersStore.length - 1) {
      nuicallback("click", true);

      handlecharacterswitch(counter + 1);
    }
  };

  useEffect(() => {
    const handlemessage = (event) => {
      switch (event.data.action) {
        case "characterselection":
          dispatch(updatescreen("characterselection"));
          SetPlayersStore(event.data.data);
          break;
      }
    };

    window.addEventListener("message", handlemessage);
    return () => window.removeEventListener("message", handlemessage);
  }, []);

  return (
    <>
      {scene == "deleteconfirm" ? (
        <DeleteConfirm id={counter + 1} />
      ) : (
        <div
          style={{ display: scene == "characterselection" ? "flex" : "none" }}
          className="h-screen an"
        >
          <div className="absolute top-[45%] left-[70px] translate-y-[-50%] outline-0 border-0 flex gap-4 items-baseline ">
            {playersStore &&

                  <div
                    className="min-w-[400px] flex flex-col gap-3"
                    key={playersStore[counter].id}
                  >
                    <div className="relative top-4">
                      <div className="absolute mt-[55px] ml-[-35px] flex items-center justify-center text-[12px] bg-[rgba(0,0,0,0.5)] hover:bg-[rgba(0,0,0,0.8)] text-white w-[25px] h-[25px] rounded-[50%] font-bold border-[#C9C9C9] border-[1px]">
                        <div>{playersStore[counter].id}</div>
                      </div>

                      <div className=" relative left-1 top-3 text-[20px] tracking-[6px] uppercase text-[#ffffff86] ">
                        {playersStore[counter].lastname}
                      </div>
                      <div className="text-[48px] font-bold uppercase  text-[#FFFFFF] ">
                        {playersStore[counter].firstname}
                      </div>
                    </div>

                    <div className="w-[380px] h-[3px] bg-gradient-to-r from-[#ffffff86] to-[rgba(0,0,0,0)]"></div>

                    <ul className="text-[20px] flex flex-row gap-4">
                      {Object.keys(playersStore[counter].additionalInfo).map((p, i) => (
                        <li
                          key={p}
                          onMouseEnter={() => nuicallback("hover")}
                          className="flex flex-col w-[38px] h-[38px] items-center justify-center   bg-[rgba(0,0,0,0.5)] border-[1px] border-[#C9C9C9] gap-2 inf"
                        >
                          <img src={icons[i].icon} alt="person" />
                          <span className="text-white absolute mt-[80px] uppercase text-[10px] font-bold">
                            {formatNumberToCurrency(playersStore[counter].additionalInfo[p])}
                          </span>
                        </li>
                      ))}

                      <li
                        onClick={() => {
                          dispatch(updatescreen("settings"));
                          nuicallback("click");
                        }}
                        onMouseEnter={() => nuicallback("hover")}
                        className="flex flex-col w-[38px] h-[38px] items-center justify-center   bg-[rgba(0,0,0,0.5)] border-[1px] border-[#C9C9C9] gap-2 inf"
                      >
                        <img src={settingsicon} alt="person" />
                        <span className="text-white absolute mt-[80px] uppercase text-[10px] font-bold">
                          SETTINGS
                        </span>
                      </li>
                    </ul>
                  </div>
                }
          </div>

          <div className="absolute bottom-[3%]  left-[50%] translate-x-[-50%] flex flex-row items-center">
            <img
              className="p-2 opacity-80 hover:opacity-100"
              onMouseEnter={() => nuicallback("hover")}
              src={lefticon}
              onClick={handleQ}
              alt=""
            />

            <div className="overflow-hidden w-[435px] flex flex-row items-center">
     

            <div
                className="transition-[500ms] p-[10px] flex items-center justify-center"
                style={{ transform: `translate(${-145 * counter}px)` }}
              >
                <div
                  className="bg-[#00000086] w-[125px] h-[150px] border-[1px] border-[#C9C9C9] flex flex-col justify-between transition deletebutton"
                  style={{
                    background: `radial-gradient(circle, rgba(0,0,0,0) 0%, rgba(0,0,0,0.65) 100%)`,
                    backgroundPosition: "center",
                  }}
                ></div>
              </div>

              {playersStore && playersStore.map((player) => (
                <div
                  className="transition-[500ms] p-[10px] flex items-center justify-center"
                  style={{ transform: `translate(${-145 * counter}px)` }}
                >
                  <div
                    className="bg-[#00000086] w-[125px] h-[150px] border-[1px] border-[#C9C9C9] flex flex-col justify-between transition deletebutton bg-[length:120px]"
                    style={{
                      transform:
                        counter + 1 == player.id ? "scale(1.1)" : "scale(1.0)",
                      backgroundImage: `radial-gradient(circle, rgba(0,0,0,0) 0%, rgba(0,0,0,0.65) 100%), url(${player.img}), url(${player.emptyslot ? createicon : player.sex ? profilepicture : profilefemale})`,
                      backgroundPosition: "center",
                    }}
                  >
                    <div className=" w-[125px] flex items-end justify-end p-2">
                      {counter + 1 == player.id && !player.emptyslot && (
                        <svg
                          onMouseEnter={() => nuicallback("hover")}
                          onClick={() => {
                            dispatch(updatescreen("deleteconfirm"));
                            nuicallback("click");
                          }}
                          className="fill-[#dd2020] hover:fill-[#af1616] w-[13px]"
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 448 512"
                        >
                          <path d="M135.2 17.7L128 32 32 32C14.3 32 0 46.3 0 64S14.3 96 32 96l384 0c17.7 0 32-14.3 32-32s-14.3-32-32-32l-96 0-7.2-14.3C307.4 6.8 296.3 0 284.2 0L163.8 0c-12.1 0-23.2 6.8-28.6 17.7zM416 128L32 128 53.2 467c1.6 25.3 22.6 45 47.9 45l245.8 0c25.3 0 46.3-19.7 47.9-45L416 128z" />
                        </svg>
                      )}
                    </div>
                    <div className="text-[#FFFFFF] font-bold uppercase flex justify-center items-center w-[100%] flex-col p-2">
                      <div className="relative top-2 text-[13px] opacity-60">
                        {!player.emptyslot && player.lastname}
                      </div>
                      <div className="text-[20px]">
                        {player.emptyslot ? "NEW SLOT" : player.firstname}
                      </div>
                    </div>
                  </div>
                </div>
              ))}

              <div
                className="transition-[500ms] p-[10px] flex items-center justify-center"
                style={{ transform: `translate(${-145 * counter}px)` }}
              >
                <div
                  className="bg-[#00000086] w-[125px] h-[150px] border-[1px] border-[#C9C9C9] flex flex-col justify-between transition deletebutton"
                  style={{
                    background: `radial-gradient(circle, rgba(0,0,0,0) 0%, rgba(0,0,0,0.65) 100%)`,
                    backgroundPosition: "center",
                  }}
                ></div>
              </div>


            </div>

            <img
              className="p-2 opacity-80 hover:opacity-100"
              onMouseEnter={() => nuicallback("hover")}
              src={righticon}
              onClick={handleE}
              alt=""
            />
          </div>

          <div
            onClick={handleplay}
            onMouseEnter={() => nuicallback("hover")}
            className="absolute bottom-[23%] left-[50%] translate-x-[-50%] flex items-center justify-center bg-[rgba(0,0,0,0.5)]  border-[1px] border-[#C9C9C9]  hover:bg-[rgba(0,0,0,0.8)]  w-[80px] h-[40px] "
          >
            <img className="w-[20px] " src={playicon} alt="" />
          </div>
        </div>
      )}
    </>
  );
};

export default CharDetails;
